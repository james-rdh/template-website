#!/bin/bash

# Renewal loop
trap exit TERM;
while :; do
  certbot renew; 
  sleep 12h & 
  wait $${!}
done