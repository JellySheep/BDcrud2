# Лабораторная: развёртывание REST API приложения в Docker (app + PostgreSQL + MongoDB + nginx + GitLab)

## 1. Структура проекта
```
git clone https://github.com/JellySheep/BDcrud2.git
mv BDcrud2 BDcrud
```

Корень проекта (`BDcrud/`):

- `app/` – исходный код REST API-приложения.
- `Dockerfile` – сборка образа приложения.
- `docker-compose.yml` – приложение + PostgreSQL + MongoDB + nginx.
- `nginx/nginx.conf` – конфигурация nginx, который работает как reverse proxy к приложению.
- `sql/init_postgres.sql` – скрипт инициализации БД PostgreSQL (создание таблицы `products`).
- `certs/`
  - `nginx.crt` – публичный сертификат для nginx.
  - `localhost.crt` – может использоваться для других тестов.
- `secrets/`
  - `nginx.key` – приватный ключ TLS для nginx (не входит в репозиторий).
  - `localhost.key` – приватный ключ для `localhost` (не коммитится).
  - `postgres_password.txt` – пароль пользователя `postgres` (не коммитится).

Каталог `gitlab/`:

- `gitlab/docker-compose.yml` – сборщик для GitLab CE.
- `gitlab/certs/`
  - `localhost.crt` – публичный сертификат для GitLab.
- `gitlab/secrets/`
  - `gitlab_ssl.key` – приватный TLS-ключ GitLab. (их тут так же нет)
  - `gitlab_root_password.txt` – пароль пользователя `root` GitLab. (не входит)
- `gitlab/config/`, `gitlab/logs/`, `gitlab/data/` – генерируются самим GitLab: конфиги, логи, данные.

Секреты и приватные ключи не добавляются в репозиторий и игнорируются через `.gitignore`. Ниже приводятся команды для их локальной генерации.

---

## 2. Подготовка секретов и сертификатов
Работа в корне проекта - BDcrud
```bash
mkdir -p secrets certs
```
```echo "postgres" > secrets/postgres_password.txt ``` (Пароль можно заменить на любой. При первом запуске PostgreSQL инициализирует базу,
читая пароль из Docker secret `postgres_password.txt`. Приложение также использует этот же пароль,
так как формирует строку подключения `POSTGRES_DSN` динамически при старте, читая пароль
из того же Docker secret. Пароль не хранится в открытом виде в `docker-compose.yml`.)

```bash
openssl req -x509 -nodes -days 365 \
  -newkey rsa:2048 \
  -keyout secrets/nginx.key \
  -out certs/nginx.crt \
  -subj "/CN=localhost"

cd gitlab

mkdir -p certs secrets

openssl req -x509 -nodes -days 365  \
  -newkey rsa:2048 \
  -keyout secrets/gitlab_ssl.key \
  -out certs/localhost.crt \
  -subj "/CN=localhost"
```

``` echo "GitLabRoot123" > secrets/gitlab_root_password.txt ``` (пароль можно сменить, но значение берётся GitLab только при первом запуске, далее пароль хранится во внутренней БД GitLab.)

Сертификаты и пароли готовы, для проверки работы БД нужно вернуться в BDcrud 
```bash
cd ..
```
### 2.1. приложение + nginx + PostgreSQL (БД можно выбрать, пароля на монге нет)
По умолчанию приложение использует PostgreSQL как основное хранилище.
Выбор хранилища управляется переменной окружения STORAGE:
STORAGE=postgres – использовать PostgreSQL (по умолчанию);
STORAGE=mongo – использовать MongoDB;
STORAGE=memory – использовать встроенное in-memory-хранилище.
Пример запуска с MongoDB:
```STORAGE=mongo docker compose up -d --build```
```bash
docker compose up -d --build

docker compose ps
```
API приложения доступен через HTTPS за nginx по адресу:
https://localhost/products
```bash
curl -k -X POST https://localhost/products \
  -H "Content-Type: application/json" \
  -d '{"name":"TestBD","description":"from_lab_test","price":222.0,"qty":333,"category":"lab"}'

curl -k https://localhost/products | grep TestBD

docker exec -it bdcrud-postgres-1 \
  psql -U postgres -d postgres \
  -c "SELECT id, name, price, qty, category FROM products;"
```
секрет описан в docker-compose.yml:
./secrets/postgres_password.txt;
контейнер PostgreSQL читает пароль через переменную POSTGRES_PASSWORD_FILE=/run/secrets/postgres_password;
контейнер приложения также получает этот секрет и формирует строку подключения POSTGRES_DSN внутри entrypoint-скрипта, а не из открытого текста в docker-compose.yml.

### 2.2. GitLab

Развёртывание GitLab выполняется из каталога gitlab/:
```bash
cd gitlab

docker compose up -d
```
#### 5 минут можно попить чай

------------------------------
```bash
docker ps

Проверка HTTP-доступа (ожидается редирект на HTTPS):
curl -I http://localhost:8081

Проверка HTTPS-доступа к GitLab:
curl -k -I -L https://localhost:8443

Ожидается статус 200 OK главной страницы GitLab по HTTPS.
curl -k -I -L https://localhost:8443/users/sign_in
```










