FROM vault
ADD docker/entryPoint.sh /
ADD docker/config.sh /
RUN chmod +x /entryPoint.sh
RUN chmod +x /config.sh
ENTRYPOINT ["sh", "/entryPoint.sh"]