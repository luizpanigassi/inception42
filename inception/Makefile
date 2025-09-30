NAME = inception

all: build up

build:
	docker-compose -f $(HOME)/inception/srcs/docker-compose.yml build

up:
	docker-compose -f $(HOME)/inception/srcs/docker-compose.yml up -d

down:
	docker-compose -f $(HOME)/inception/srcs/docker-compose.yml down

re: down all
