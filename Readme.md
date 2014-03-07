# Reception

A simple guest tracking app for vibe.

![img](http://f.cl.ly/items/1j2R1N3b3Z3W1Z1o3P03/heroku%20guests%202014-02-26%2011-43-46%202014-02-26%2011-43-52.png)

## Setup

```bash
bundle install
cp .env.example .env
```

**Create an OAuth client**
```bash
heroku plugins:install git://github.com/heroku/heroku-oauth.git
heroku clients:register "reception-localhost" http://localhost:5000/auth/heroku/callback
```

Add these values to `HEROKU_OAUTH_ID` and `HEROKU_OAUTH_SECRET`.

**Create database**
```bash
createdb guest
psql guest -f schema.sql
```

**Enjoy**
```bash
foreman start
```
