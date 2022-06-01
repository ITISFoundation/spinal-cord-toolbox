FROM nginx:1.19.1-alpine as production

EXPOSE 8080
RUN rm /etc/nginx/conf.d/default.conf
RUN chmod a+rwx /etc/nginx/conf.d
COPY config/nginx.conf /etc/nginx/templates/default.conf.template

CMD ["nginx", "-g", "daemon off;"]
