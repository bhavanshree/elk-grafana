### ELK Setup
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
    volumes:                                                 -/home/emadmin/ELK/filebeat/filebeat.yml:/usr/share/filebeat/filebeat.yml
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

