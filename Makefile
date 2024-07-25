 PROJECT_DIR = nante

.PHONY: All
ALL: ruby-configure \
	cocoapod-configure

.PHONY: ruby-configure
ruby-configure:
	if [ ! -e /usr/local/bin/rbenv ]; then\
		brew install rbenv; \
	fi

	export CONFIGURE_OPTS="--disable-install-doc --disable-install-rdoc --disable-install-copi"
	rbenv install 3.2.3 -v -s
	rbenv local 3.2.3
	rbenv exec gem install bundler
	rbenv rehash
	cd ${PROJECT_DIR} && \
	bundle install --path vendor/bundle

.PHONY: cocoapod-configure
cocoapod-configure:
	cd ${PROJECT_DIR} && \
	bundle exec pod install --repo-update
