# NGINX 1.13.3, NAXSI 0.55.3, SSL SNI and GeoIP RUNNING ON ALPINE LINUX.

** Please use the docker compose file from my github repository to run this container and understand what you need to adapt to your environment/app. **

This image depends on the latest image of elasticsearch (5.5) and kibana (5.5). The file kibana_objs.json on my github repository is the dashboard and basic graphs I've created. To kibana works well you need to wait for the first error log ingestion, it will create the mappings on elasticsearch index and populate the WAF dashboard. The docker-compose file creates two named volumes to keep the elasticsearch (esdata) and kibana (kbndata) data over restarts, if you want to keep those data never use the option -v when turning down your compose (`docker-compose down -v`) and don't use `docker volume prune` too.

Screenshot of dashboard using Kibana:
![alt text](https://raw.githubusercontent.com/amioranza/naxsi/master/dashboard.png "Kibana Dashboard")

I hope you enjoy this image.
