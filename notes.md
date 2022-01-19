```
#Migration:
sudo apt update
sudo apt install -y docker docker-compose

#make volumes
sudo mkdir /docker
mkdir /docker/bnpp
mkdir /docker/bnpp/log
mkdir /docker/bnpp/db
mkdir /docker/bnpp/solr
mkdir /docker/bnpp/solr/config/
mkdir /docker/bnpp/solr/data/
sudo chmod 777 -R /docker # that's not right, map all to a bnpp account?
```


```
# get the code
git clone https://github.com/peer35/bnpp
cd bnpp
git checkout docker

# copy the config to '/docker/bnpp/solr/config/
cp -r solr/conf/* /docker/bnpp/solr/config/
```
- Set sensible data in .env, use `rails generate secret`
`nano .env`

- Add the admins
`nano config/initializers/admins.rb`

- Create a dump of the production database
- Restore db dump:
```
sudo docker-compose up -d bnpp-db
cat bnpp_production25.dump | sudo docker exec -i bnpp-db psql -U blacklight -d bnpp
```

# Build the rest and see if it starts successfully
```
sudo docker-compose up
```

- Start the cointainers normally
```        
sudo docker-compose up -d
```

- reindex: `/records/record/indexall`