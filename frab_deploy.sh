#!/bin/bash

DATABASE_PASS="ididnotreadtheinstructions"
FRAB_DB_USER="ididnotread"
FRAB_DB_PASS="ididnotreadtheinstructions"
FRAB_DB="ididnotreadtheinstructions"
FRAB_DEVEL_DB="ididnotreadtheinstructions2"
FRAB_TEST_DB="ididnotreadtheinstructions3"

# Install the prerequisites
apt-get -qq update
DEBIAN_FRONTEND=noninteractive apt-get -qq install nodejs imagemagick git-core mysql-server mysql-server-5.5 ruby-passenger libmysqlclient-dev libpq-dev libsqlite3-dev libapache2-mod-passenger apache2 rbenv ruby-build

# Initial MySQL setup, like running mysql_secure_installation
mysqladmin -u root password "$DATABASE_PASS"
mysql -u root -p"$DATABASE_PASS" -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1')"
mysql -u root -p"$DATABASE_PASS" -e "DELETE FROM mysql.user WHERE User=''"
mysql -u root -p"$DATABASE_PASS" -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\_%'"
mysql -u root -p"$DATABASE_PASS" -e "FLUSH PRIVILEGES"

# Add frab DB settings
mysql -u root -p"$DATABASE_PASS" -e "CREATE DATABASE $FRAB_DEVEL_DB"
mysql -u root -p"$DATABASE_PASS" -e "CREATE DATABASE $FRAB_TEST_DB"
mysql -u root -p"$DATABASE_PASS" -e "CREATE DATABASE $FRAB_DB"
mysql -u root -p"$DATABASE_PASS" -e "CREATE USER $FRAB_DB_USER@'localhost' IDENTIFIED BY '$FRAB_DB_PASS'"
mysql -u root -p"$DATABASE_PASS" -e "GRANT ALL PRIVILEGES ON $FRAB_DEVEL_DB.* TO $FRAB_DB_USER@'localhost'"
mysql -u root -p"$DATABASE_PASS" -e "GRANT ALL PRIVILEGES ON $FRAB_TEST_DB.* TO $FRAB_DB_USER@'localhost'"
mysql -u root -p"$DATABASE_PASS" -e "GRANT ALL PRIVILEGES ON $FRAB_DB.* TO $FRAB_DB_USER@'localhost'"
mysql -u root -p"$DATABASE_PASS" -e "FLUSH PRIVILEGES"

# Add a RoR user
useradd -s /usr/sbin/nologin -m rails

# Clone the repository
su -l -s /bin/bash -c 'git clone -q https://github.com/frab/frab.git /home/rails/frab-app' rails

# Install Ruby using rbenv
su -l -s /bin/bash -c 'rbenv install 1.9.3-p194 --disable-install-rdoc' rails
su -l -s /bin/bash -c 'rbenv global 1.9.3-p194' rails
su -l -s /bin/bash -c "echo "'eval "$(rbenv init -)"'" > /home/rails/.bash_aliases" rails

su -l -s /bin/bash -c '. /home/rails/.bash_aliases; gem install bundler --no-rdoc --no-ri' rails

# Setup the config files
#cp /srv/frab-app/config/database.yml.template /srv/frab-app/config/database.yml
cat > /home/rails/frab-app/config/database.yml <<EOF
development:
  adapter: mysql2
  encoding: utf8
  database: $FRAB_DEVEL_DB
  username: $FRAB_DB_USER
  password: $FRAB_DB_PASS
  host: localhost
  port: 3306

test:
  adapter: mysql2
  encoding: utf8
  database: $FRAB_TEST_DB
  username: $FRAB_DB_USER
  password: $FRAB_DB_PASS
  host: localhost
  port: 3306

production:
  adapter: mysql2
  encoding: utf8
  database: $FRAB_DB
  username: $FRAB_DB_USER
  password: $FRAB_DB_PASS
  host: localhost
  port: 3306
EOF
su -l -s /bin/bash -c 'cp /home/rails/frab-app/config/settings.yml.template /home/rails/frab-app/config/settings.yml' rails

su -l -s /bin/bash -c '. /home/rails/.bash_aliases; cd /home/rails/frab-app && bundle install' rails

su -l -s /bin/bash -c '. /home/rails/.bash_aliases; cd /home/rails/frab-app && bundle exec rake db:setup RAILS_ENV=production' rails
su -l -s /bin/bash -c '. /home/rails/.bash_aliases; cd /home/rails/frab-app && bundle exec rake assets:precompile' rails

# Replace the secret token
RAKE_SECRET="$(su -l -s /bin/bash -c ". /home/rails/.bash_aliases; cd /home/rails/frab-app && bundle exec rake secret" rails)"
su -l -s /bin/bash -c 'cp /home/rails/frab-app/config/initializers/secret_token.rb.example /home/rails/frab-app/config/initializers/secret_token.rb' rails
sed -i "s/^Frab::Application.config.secret_token =.*/Frab::Application.config.secret_token = '$RAKE_SECRET'/" /home/rails/frab-app/config/initializers/secret_token.rb

cat > /etc/apache2/sites-available/001-frab.conf <<'EOF'
<VirtualHost *:80>
    ServerName frab.demo.local
    ServerAlias www.frab.demo.local
    ServerAdmin webmaster@localhost
    DocumentRoot /home/rails/frab-app/public
    #RailsEnv development
    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
    <Directory "/home/rails/frab-app/public">
        Options FollowSymLinks
        Require all granted
    </Directory>
</VirtualHost>
EOF

a2dissite 000-default
a2ensite 001-frab

# ugly hack pointing to a fixed Ruby version
sed -i "sB /usr/bin/rubyB /home/rails/.rbenv/versions/1.9.3-p194/bin/rubyB" /etc/apache2/mods-available/passenger.conf

service apache2 restart
