- bnpp dockerfile based on ruby image
  - mounts the solr-config volume
  - mount config dir? Or at least move the admins.rb?

  - Docker file:
    - Copy the code dirs 
    - gem install
    - rails db:create db:migrate, so needs a linked postgres image?