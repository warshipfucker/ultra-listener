# Используем образ Ubuntu
FROM ubuntu:latest

# Установка необходимых пакетов
RUN apt-get update && apt-get install -y --no-install-recommends \
    ncat \
    openssh-server \
    telnet \
    vsftpd \
    samba \
    php \
    php-soap \
    php-sockets \
    curl \
    python3 \
    python3-flask \
    socat && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Настройка портов
EXPOSE 22 2222 23 21 139 40 80 8000 8080 25 1234 4321

# Настройка SSH-сервера
RUN echo "PermitRootLogin yes" >> /etc/ssh/sshd_config && \
    service ssh start && \
    service ssh restart

# Добавление пользователя для SCP
RUN useradd -m scpuser && echo "scpuser:password" | chpasswd && \
    echo "scpuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Настройка Samba (SMB)
RUN echo -e "[global]\nworkgroup = WORKGROUP\nnetbios name = docker-smb\nsecurity = user\nmap to guest = Bad User\n" > /etc/samba/smb.conf && \
    echo -e "[public]\npath = /var/smb\nbrowsable = yes\nwritable = yes\nguest ok = yes\ncreate mask = 0755\n" >> /etc/samba/smb.conf && \
    mkdir -p /var/smb && chmod -R 0755 /var/smb && chown -R nobody:nogroup /var/smb

# Настройка WebDAV
RUN mkdir /var/www/webdav && chown www-data:www-data /var/www/webdav

# Создание файла загрузки
COPY ./upload_form.html /var/www/html/upload_form.html
RUN chmod 755 /var/www/html/upload_form.html


# Команды для запуска служб
CMD ["/bin/sh", "-c", "service ssh start && socat TCP-LISTEN:1234,fork EXEC:/bin/cat & socat TCP-LISTEN:4321,fork EXEC:/bin/cat && service vsftpd start && service smbd start"]
