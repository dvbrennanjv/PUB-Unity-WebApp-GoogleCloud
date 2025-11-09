FROM nginx:alpine
COPY default.conf /etc/nginx/conf.d/default.conf
COPY unity/index.html /usr/share/nginx/html
COPY unity/Build /usr/share/nginx/html/Build
COPY unity/TemplateData /usr/share/nginx/html/TemplateData
EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]