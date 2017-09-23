<div>The separation of Graphite and Graphite-Beacon on different servers has several drawbacks. First, it increases the system complexity. The two services are logically inherent. There is no necessity to separate them. Second, the configurations have increased dependency. Each time the Graphite server changes, the Graphite-Beacon configuration may change accordingly.</div>
<div></div>
<div>Here is a proposed solution integrating the two components in one Docker. Thus, We can only build the Docker image once and run both in a single Docker container. The source code inherits two codebase, one is the Graphite Docker image and the other is the Graphite-Beacon Docker image.</div>
<div></div>
<div>If you download the Dockerfile and build the image locally, you can run it with the following docker-compose.yml file. You may need to install Docker Engine and Docker Compose first. Please refer to <a href="https://docs.docker.com/engine/installation/">Docker Engine</a> and <a href="https://docs.docker.com/compose/install/">Docker Compose</a> for installation details.</div>
<div></div>
<div>The docker-compose.yml defines the Docker image name and configurations. To run the integrated monitoring service, simply type “docker-compose run -d” from the command line at the folder path containing docker-compose.yml</div>
<div></div>
<div></div>
