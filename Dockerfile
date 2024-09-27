# Используем легковесный образ
FROM alpine:latest

# Установка необходимых пакетов
RUN apk update && apk upgrade && apk add --no-cache \
    ncat \
    openssh \
    telnet \
    vsftpd \
    samba \
    apache2 \
    php8 \
    php8-soap \
    php8-sockets \
    curl \
    python3 \
    py3-flask \
    busybox-extras \
    socat \
    inotify-tools

# Настройка портов
EXPOSE 22 2222 23 21 139 40 80 8000 8080 25 1234 4321

# Настройка SSH-сервера
RUN echo "PermitRootLogin yes" >> /etc/ssh/sshd_config \
    && sed -i '/^#PermitRootLogin/s/#//' /etc/ssh/sshd_config

# Добавление пользователя для SCP
RUN adduser -D -h /home/scpuser scpuser && echo "scpuser:password" | chpasswd

# Настройка Samba (SMB)
RUN echo -e "[global]\nworkgroup = WORKGROUP\nnetbios name = docker-smb\nsecurity = user\nmap to guest = Bad User\n" > /etc/samba/smb.conf \
    && echo -e "[public]\npath = /var/smb\nbrowsable = yes\nwritable = yes\nguest ok = yes\ncreate mask = 0755\n" >> /etc/samba/smb.conf \
    && mkdir -p /var/smb && chmod -R 0755 /var/smb && chown -R nobody:nogroup /var/smb

# Настройка WebDAV
RUN mkdir /var/www/webdav && chown apache:apache /var/www/webdav

# Создание файла загрузки
COPY ./upload_form.html /var/www/localhost/htdocs/
RUN chmod 755 /var/www/localhost/htdocs/upload_form.html

# Настройка Telnet
RUN echo "telnet stream tcp nowait root /bin/busybox telnetd" >> /etc/inetd.conf

# Команды для запуска служб
CMD ["/bin/sh", "-c", "sshd && socat TCP-LISTEN:1234,fork EXEC:/bin/cat & socat TCP-LISTEN:4321,fork EXEC:/bin/cat & httpd -DFOREGROUND & vsftpd & smbd -F & /usr/sbin/inetd"]
