#!/bin/bash 

cd config
mvn compile jib:build \
    -Djib.container.environment=CONFIG_SERVICE_PASSWORD=${{ env.CONFIG_SERVICE_PASSWORD }}
cd ../registry
mvn compile jib:build 
cd ../gateway
mvn compile jib:build
cd ../auth-service
mvn compile jib:build 

cd ../account-service
mvn compile jib:build \
    -Djib.container.environment=ACCOUNT_SERVICE_PASSWORD=${{ env.ACCOUNT-SERVICE-PASSWORD }} 
    
cd ../statistics-service
mvn compile jib:build \
    -Djib.container.environment=STATISTICS_SERVICE_PASSWORD=${{ env.STATISTICS-SERVICE-PASSWORD }} 
cd ../notification-service
mvn compile jib:build \
    -Djib.container.environment=NOTIFICATION_SERVICE_PASSWORD=${{ env.NOTIFICATION-SERVICE-PASSWORD }} 
echo 'Build complete'


helm install initialdeploy buildachart-piggy
