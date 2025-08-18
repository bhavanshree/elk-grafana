## Services and Port
| Server        | Service             | Port  |
|---------------|---------------------|-------|
| 130.78.204.143 | Frontend            | 9090  |
|               | Keycloak-uat        | 8443  |
|               | Node-exporter       | 9100  |
| 130.78.204.115 | Result              | 7772  |
|               | Order               | 8084  |
|               | Registration        | 8082  |
|               | Gateway             | 7791  |
|               | Acknowledge         | 8087  |
|               | Userprofile         | 8081  |
|               | Testbase            | 8086  |
|               | Patient             | 8083  |
|               | Facility            | 8085  |
|               | Apigateway          | 7790  |
|               | Node-exporter       | 9100  |
| 130.78.204.144 | Elk-elasticsearch-1 | 9200  |
|               | Elk-kibana-1        | 5601  |
|               | Redis-prod          | 16370 |
|               | Grafana             | 3000  |
|               | Prometheus          | 9090  |
|               | Node-exporter       | 9100  |
|               | Keycloak-db         | 15432 |
| 130.78.204.142 | Oracle              | 1521  |

## Application-version
| Application   | Version |
|---------------|---------|
| Docker        | 28.0.1  |
| Keycloak      | 26.0.5  |
| Postgres      | 16      |
| Redis         | 5.0.14  |
| Elasticsearch | 7.17.0  |
| Kibana        | 7.17.0  |
| Filebeat      | 7.17.0  |


## Redis setup
```
docker run -d   --name redis-stage  -p 16370:6379   -v ./redis.conf:/usr/local/etc/redis/redis.conf   redis:5.0.14 redis-server /usr/local/etc/redis/redis.conf
```
## Dedalus help
- Set up an Nginx folder along with its configuration.
-  Since that folder doesn’t have an index.html, update the Nginx configuration accordingly.
```
worker_processes 1;

events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    server {
        listen 80;
        server_name localhost;

        root /usr/share/nginx/html;
        index index.html;

        location / {
            autoindex on;  # Optional: shows folder contents if no index
            add_header Access-Control-Allow-Origin *;
            add_header Access-Control-Allow-Methods 'GET, POST, OPTIONS';
            add_header Access-Control-Allow-Headers 'Origin, Content-Type, Accept';
        }

    }
}
```
- Created a Dockerfile for the folder.
**Dockerfile**
```
FROM nginx:alpine
RUN rm -rf /usr/share/nginx/html/*
COPY . /usr/share/nginx/html/
COPY ./nginx/nginx.conf /etc/nginx/nginx.conf
CMD ["nginx", "-g", "daemon off;"]
```
- Once the Docker file is created, build the image
```
docker build -t <image_name>:v1 -no-cache .
```
- Push into the Docker Hub
```
docker push <image_name>:v1
```
-  Docker run Commands for the server
```
docker run -d --name dedalus-help -p <Expose-port>:80 <image-name>:v1
```
**Example Outpit**
  ![image alt](https://github.com/bhavanshree/elk-grafana/blob/5e539010568c766c168318736462691950e65a3c/images/help-Index.png)
  ![image alt](https://github.com/bhavanshree/elk-grafana/blob/5e539010568c766c168318736462691950e65a3c/images/result.png)

## Keycloak setup
**Postgres DB(Keycloak):**
- Pull the Postgres Image.
```
docker pull postgres:16
```
- Create a Docker Volume.
```
docker volume create keycloak-data
```
- Run the postgres data as a container.
```
docker run -d   --name keycloak-db --restart=always   -e POSTGRES_USER=<Username>  -e POSTGRES_PASSWORD=<Password>  -e POSTGRES_DB=<DB Name>   -p <Expose Port>:5432   -v keycloak-data:/var/lib/postgresql/data   postgres:16
```
**Keycloak Setup(app):**
- Pull the Keycloak Docker Image. 
```
docker pull quay.io/keycloak/keycloak:26.0.5
```
- Run the keycloak as a container.
```
docker run -d --name keycloak --restart=always -p 8443:8080 -e KC_BOOTSTRAP_ADMIN_USERNAME=admin -e KC_BOOTSTRAP_ADMIN_PASSWORD=admin -e KC_DB=postgres -e KC_DB_URL=jdbc:postgresql://<DB_Host>:<DB_Port/<DB_Name> -e KC_DB_USERNAME=<DB_Username> -e KC_DB_PASSWORD=<DB_Password> quay.io/keycloak/keycloak:26.0.5 start-dev
```





# ELK Setup
- Use the below mentioned docker-compose.yml to setup the elk.
```
version: '3.8'

services:
  elasticsearch:
    image: "docker.elastic.co/elasticsearch/elasticsearch:7.17.0"
    environment:
      - "ES_JAVA_OPTS=-Xms1g -Xmx1g"
      - "discovery.type=single-node"
      - "xpack.security.enabled=true"
      - "ELASTIC_PASSWORD=ElastIcadMin"
    ports:
      - "9200:9200"
    volumes:
      - elasticsearch_data:/usr/share/elasticsearch/data

  kibana:
    image: "docker.elastic.co/kibana/kibana:7.17.0"
    environment:
      - "ELASTICSEARCH_HOSTS=http://elasticsearch:9200"
      - "ELASTICSEARCH_USERNAME=elastic"
      - "ELASTICSEARCH_PASSWORD=ElastIcadMin"
      - "xpack.security.enabled=true"
    ports:
      - "5601:5601"

  filebeat:
    image: "docker.elastic.co/beats/filebeat:7.17.0"
    user: root
    volumes: 
      -/home/emadmin/ELK/filebeat/filebeat.yml:/usr/share/filebeat/filebeat.yml
      - /var/lib/docker:/var/lib/docker:ro
      - /var/run/docker.sock:/var/run/docker.sock

volumes:
  elasticsearch_data:
```

- I ‘ve attached the screenshot for the file structure

  ![image alt](https://github.com/bhavanshree/elk-grafana/blob/324291bf36ea490c54e5977e0a2c0687a27e5060/images/Elk-folder.png)
- Execute this command in the ELK directory.
```
docker-compose up -d
```

### Filebeat Setup
- Use the below-mentioned filebeat.yml file and cli command to setup the filebeat container for showing the application logs to kibana dashboard.
```
filebeat.inputs:
- type: docker
  containers.ids:
    - "*"
  processors:
    - add_docker_metadata: ~
    - add_fields:
        target: ""
        fields:
          container_name_tag: "%{[docker.container.name]}"

output.elasticsearch:
  hosts: ["http://<Elasticsearch_Host>:9200"]
  username: "elastic"
  password: "ElastIcadMin"
  indices:
    - index: "dedalus-fe-%{+yyyy.MM.dd}"
  setup.template.name: "dedalus-fe"
  setup.template.pattern: "dedalus-fe-*"
```
- Set the privilege to the filebeat.yml file.
```
chmod 640 filebeat.yml
chown root:root filebeat.yml
```
> [!NOTE]
> To run Filebeat independently on a different server, the filebeat.yml configuration file is required on that server. In a setup with three servers—one hosting the full ELK stack and the other two running only Filebeat—each Filebeat instance connects to the ELK server to forward container logs.

  ![image alt](https://github.com/bhavanshree/elk-grafana/blob/99e26f2e2a38e13a5886f18268b5eda6342a5ef7/images/filebeat-folder.png)

- Use the below command to run the filebeat container.
```
docker run -d --name=filebeat   --user=root   --volume="/var/lib/docker/containers:/var/lib/docker/containers:ro"   --volume="/var/run/docker.sock:/var/run/docker.sock:ro"   --volume="$(pwd)/filebeat.yml:/usr/share/filebeat/filebeat.yml:ro"   docker.elastic.co/beats/filebeat:7.17.0 filebeat -e -strict.perms=false -c /usr/share/filebeat/filebeat.yml
```

### ELK setup in application

Open the browser  and search :<Elasticsearch_Host>:5601
```
User name: elastic
Password: ElastIcadMin
```
- Steps to follow:

  - Go to the stack management in the left side and click the index pattern under the Kibana section
    ![image alt](https://github.com/bhavanshree/elk-grafana/blob/99e26f2e2a38e13a5886f18268b5eda6342a5ef7/images/kibana-home.png)
    ![image alt](https://github.com/bhavanshree/elk-grafana/blob/99e26f2e2a38e13a5886f18268b5eda6342a5ef7/images/index.png)

  - Then click on **Create index pattern** to set up a new index pattern.
    ![image alt](https://github.com/bhavanshree/elk-grafana/blob/99e26f2e2a38e13a5886f18268b5eda6342a5ef7/images/create-index.png)

  - In the **Name** field, enter an appropriate name for the index, and select the corresponding **Timestamp** field..
  - After that the index pattern will be created.
  - To view the logs, navigate to the **Logs** section under **Observability**.
    ![image alt](https://github.com/bhavanshree/elk-grafana/blob/99e26f2e2a38e13a5886f18268b5eda6342a5ef7/images/stream-section.png)

  - Click on **Settings** in the top-right corner of the container, update the current log indices, and then click **Apply** at the bottom to save the changes.
    ![image alt](https://github.com/bhavanshree/elk-grafana/blob/10b26f955c12365b7a03ebd08bf21aa61f1ed0a8/images/setting.png)

  - To view the logs, navigate to the **Stream** section under **Logs** and search using the container name.
    ![image alt](https://github.com/bhavanshree/elk-grafana/blob/10b26f955c12365b7a03ebd08bf21aa61f1ed0a8/images/stream-logs.png)
  - **Syntax**: container.name: container-name

# Monitoring setup
## Prometheus and Grafana Setup:
- Use the below-mentioned docker-compose.yml file and prometheus.yml file for setting up the Monitoring-Stack.
docker-compose.yml
```
version: '3'

services:
  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    restart: unless-stopped
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus_data:/prometheus
    networks:
      - monitoring

  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    restart: unless-stopped
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin  # Set Grafana admin password
    volumes:
      - grafana_data:/var/lib/grafana
    networks:
      - monitoring
    depends_on:
      - prometheus
  node-exporter:
    image: prom/node-exporter:latest
    container_name: node-exporter
    restart: unless-stopped
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/rootfs:ro
    command:
      - '--path.procfs=/host/proc'
      - '--path.rootfs=/rootfs'
      - '--path.sysfs=/host/sys'
      - '--collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)($$|/)'
    ports:
      - 9100:9100
    networks:
      - monitoring

networks:
  monitoring:
    driver: bridge

volumes:
  prometheus_data:
  grafana_data:
```
```
docker-compose up -d
```
**Prometheus.yml**
```
global:
  scrape_interval: 15s
  evaluation_interval: 15s
  query_log_file: /prometheus/query.log

scrape_configs:

  - job_name: 'Dev Web Server'
    scrape_interval: 15s
    scrape_timeout: 10s
    static_configs:
      - targets: ['<Web Server NodeExporter_Host>:9100']

  - job_name: 'Dev API Server'
    scrape_interval: 15s
    scrape_timeout: 10s
    static_configs:
      - targets: ['<API Server NodeExporter_Host>:9100']

  - job_name: 'Dev Monitoring Server'
    scrape_interval: 15s
    scrape_timeout: 10s
    static_configs:
      - targets: ['<Monitoring Server NodeExporter_Host>:9100']
```
> [!NOTE]
> In a setup with three servers, one server hosts the full stack—Grafana, Prometheus, and Node Exporter—while the other two servers run only Node Exporter. These exporters collect system metrics and send them to Prometheus, which can then be visualized in Grafana.

## Node Exporter Setup:
- Use the below-mentioned docker-compose.yml file for setting up the node exporter service.
```
version: '3.8'

networks:
  monitoring:
    driver: bridge


volumes:
  prometheus_data: {}
  grafana-data:
    driver: local
services:
  node-exporter:
    image: prom/node-exporter:latest
    container_name: node-exporter
    restart: unless-stopped
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/rootfs:ro
    command:
      - '--path.procfs=/host/proc'
      - '--path.rootfs=/rootfs'
      - '--path.sysfs=/host/sys'
      - '--collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)($$|/)'
    ports:
      - 9100:9100
    networks:
      - monitoring
```
```
docker-compose up -d
```
## Grafana setup in the application
Log in using the default credentials:
```
Username – admin
Password – admin

```
- In the home section, choose the dashboard
 ![image alt](https://github.com/bhavanshree/elk-grafana/blob/fc7efe2f60167eaa939d55a41a7e3602aacdd50a/images/dashboard.png)
- Go to the open menu and click **Add new connection**
 ![image alt](https://github.com/bhavanshree/elk-grafana/blob/fc7efe2f60167eaa939d55a41a7e3602aacdd50a/images/add-new-connnection.png)
- Search and choose **Prometheus**.
  ![image alt](https://github.com/bhavanshree/elk-grafana/blob/fc7efe2f60167eaa939d55a41a7e3602aacdd50a/images/Promethesus.png)
- Click **Add new data source**
  Set the url to http://prometheus:9090 (service named prometheus)
  ![image alt](https://github.com/bhavanshree/elk-grafana/blob/fc7efe2f60167eaa939d55a41a7e3602aacdd50a/images/add-new-datasource.png)

- Click **Save&test**
- Go to the open menu and click **Dashboards**.
- Go to the + icon on the Top right corner and click the **Import dashboard**.
- Enter **1860** in the Find and import dashboards for common applications at [grafana.com/dashboards](grafana.com/dashboards) to import the node-exporter dashboard.

  ![image alt](https://github.com/bhavanshree/elk-grafana/blob/fc7efe2f60167eaa939d55a41a7e3602aacdd50a/images/import-dashboard.png)
- Select the Prometheus data source configured earlier
  ![image alt](https://github.com/bhavanshree/elk-grafana/blob/fc7efe2f60167eaa939d55a41a7e3602aacdd50a/images/metrics.png)



