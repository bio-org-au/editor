# NOTE: This is primarily for TeamCity use atm.
#
# Use the official Ruby image as a base image
FROM ruby:3.4.5-bullseye

RUN apt-get update -qq && apt-get install -yq --no-install-recommends \
  build-essential \
  bash \
  wget \
  curl \
  ed

RUN apt-get update -qq && apt-get install -y \
  libpq-dev

# Copy the Gemfile and Gemfile.lock
COPY ./Gemfile ./Gemfile.lock ./

# Install gems
RUN bundle install

WORKDIR /ruby-editor

# Copy the rest of the application code
COPY . ./
Run cp -r .nsl/ /root/

CMD ["/bin/bash", "-c", "echo 'Container started!' && echo 'Running post-start commands...' && RAILS_ENV=production rake build_prod && cd .. && pwd && ls -l && tar cfz ruby-editor.tgz ruby-editor && mv /ruby-editor.tgz /output/"]
