ARG IMAGE=intersystems/iris:2019.1.0S.111.0
ARG IMAGE=store/intersystems/iris:2019.1.0.511.0-community
ARG IMAGE=store/intersystems/iris:2019.2.0.107.0-community
#ARG IMAGE=intersystems/iris:2019.3.0.302.0
ARG IMAGE=intersystemscommunity/mlte:aa
FROM $IMAGE

USER root
WORKDIR /opt/ops
RUN chown ${ISC_PACKAGE_MGRUSER}:${ISC_PACKAGE_IRISGROUP} /opt/ops

USER ${ISC_PACKAGE_MGRUSER}

# copy files
COPY  Installer.cls .
COPY  src src
COPY iris.script /tmp/iris.script


# special extract treatment for hate-speech dataset
# RUN mkdir /data/hate-speech/ \
#	&& tar -xf /data/hate-speech.tar -C /data/

# load demo stuff
RUN iris start IRIS \
	&& iris session IRIS < /tmp/iris.script