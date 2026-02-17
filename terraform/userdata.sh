#!/bin/bash

# Configure ECS Cluster name
echo "ECS_CLUSTER=strapi-task7" >> /etc/ecs/ecs.config

# Start ECS service
systemctl enable ecs
systemctl start ecs
