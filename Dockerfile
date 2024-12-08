FROM ruby:2.7.3-slim
MAINTAINER Development and Operations team @ Department of Veterans Affairs
# Build variables
ENV BUILD build-essential postgresql-client libaio1 libpq-dev libsqlite3-dev curl software-properties-common apt-transport-https gnupg2 git
# Environment (system) variables
ENV LANG="AMERICAN_AMERICA.US7ASCII" \
    RAILS_ENV="development" \
    DEPLOY_ENV="demo" \
    PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH" \
    NODE_OPTIONS="--max-old-space-size=8192" \
    AWS_ACCESS_KEY_ID="dummykeyid" \
    AWS_SECRET_ACCESS_KEY="dummysecretkey" \
    AWS_SQS_ENDPOINT="http://localhost:4576"
WORKDIR /efolder
# Copy all the files
COPY . .
RUN pwd && ls -lsa
# Install VA Trusted Certificates
# RUN mkdir -p /usr/local/share/ca-certificates/va
# COPY docker-bin/ca-certs/*.crt /usr/local/share/ca-certificates/va/
# #COPY docker-bin/ca-certs/*.cer /usr/local/share/ca-certificates/va/
# RUN update-ca-certificates
# COPY docker-bin/ca-certs/cacert.pem /etc/ssl/certs/cacert.pem
RUN rm /bin/sh && ln -s /bin/bash /bin/sh
RUN apt -y update && \
    apt -y upgrade && \
    apt install -y ${BUILD} && \
    apt -y update
WORKDIR /efolder
# Install OpenSSL 3.2.0 from source
# RUN apt-get install -y wget && \
#     wget https://www.openssl.org/source/openssl-3.2.0.tar.gz && \
#     tar -zxf openssl-3.2.0.tar.gz && \
#     cd openssl-3.2.0 && \
#     ./config && \
#     make && \
#     make install && \
#     cd .. && \
#     rm -rf openssl-3.2.0 openssl-3.2.0.tar.gz
# Add OpenSSL libraries to the runtime linker path
# RUN echo "/usr/local/lib64" >> /etc/ld.so.conf.d/openssl.conf && ldconfig
# Install node
RUN mkdir /usr/local/nvm
ENV NVM_DIR /usr/local/nvm
ENV NODE_VERSION 16.16.0
ENV NVM_INSTALL_PATH $NVM_DIR/versions/node/v$NODE_VERSION
RUN curl --silent -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.11/install.sh | bash
RUN source $NVM_DIR/nvm.sh \
   && nvm install $NODE_VERSION \
   && nvm alias default $NODE_VERSION \
   && nvm use default
ENV NODE_PATH $NVM_INSTALL_PATH/lib/node_modules
ENV PATH $NVM_INSTALL_PATH/bin:$PATH
# Install Yarn
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list && \
    apt-get update && apt-get install -y yarn
# Install jemalloc
RUN apt install -y --no-install-recommends libjemalloc-dev
# install datadog agent
#RUN DD_INSTALL_ONLY=true DD_AGENT_MAJOR_VERSION=7 DD_API_KEY=$(cat config/datadog.key) bash -c "$(curl -L https://raw.githubusercontent.com/DataDog/datadog-agent/master/cmd/agent/install_script.sh)"
# Installing the version of bundler that corresponds to the Gemfile.lock
# Rake 13.0.1 is already installed, so we're uninstalling it and letting bundler install rake later.
RUN gem install bundler:$(cat Gemfile.lock | tail -1 | tr -d " ") && gem uninstall -i /usr/local/lib/ruby/gems/2.7.0 rake
RUN bundle install && \
    cd client && \
    yarn install && \
    chmod +x /efolder/docker-bin/startup.sh && \
    rm -rf docker-bin
# Run the app
ENTRYPOINT ["/bin/bash", "-c", "/efolder/docker-bin/startup.sh"]
# EXPOSE 3001
# CMD ["rails", "server", "-b", "0.0.0.0", "-p", "3001"]