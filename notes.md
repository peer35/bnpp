- Make sure bl-solr is running
```
#Migration:
sudo apt update
sudo apt install -y docker docker-compose

#make volumes
mkdir /docker/bnpp/log -p
mkdir /docker/bnpp/db -p
sudo chmod 777 -R /docker # that's not right, map all to a bnpp account?
```

```
# get the code
git clone https://github.com/peer35/bnpp
cd bnpp
git checkout docker

```

- If fresh solr config, this should create a fresh core:
```
#delete existing core
sudo docker-compose exec solr bin/solr delete -c bnpp-core
sudo docker-compose stop solr
cp -r solr/conf/* /docker/bnpp/solr/config/
sudo docker-compose up -d solr
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

- Build the rest and see if it starts successfully
```
sudo docker-compose up
```

- To start the cointainers normally
```        
sudo docker-compose up -d
```

- reindex: `/records/record/indexall`