# Как выложить репозиторий на GitHub

Репозиторий инициализирован, файлы добавлены. Ниже — настройка Git, первый коммит и выкладка на GitHub.

## 0. Настроить имя и email для Git (один раз)

Если ещё не настраивали:

```bash
git config --global user.email "ваш@email.com"
git config --global user.name "Ваше Имя"
```

## 1. Сделать первый коммит

```bash
cd C:\Users\a321s\Desktop\zapret-discord-youtube-1.9.5
git add -A
git commit -m "Initial commit: zapret-discord-youtube configs, linux-configs, bat-to-linux converter"
```

## 2. Создать репозиторий на GitHub

1. Откройте [github.com/new](https://github.com/new).
2. **Repository name:** например `zapret-discord-youtube` (или своё имя).
3. Описание по желанию. **Public**.
4. **Не** добавляйте README, .gitignore и LICENSE — они уже есть в проекте.
5. Нажмите **Create repository**.

## 3. Подключить remote и отправить код

В терминале в папке проекта выполните (подставьте **ВАШ_ЛОГИН** и **ИМЯ_РЕПО**):

```bash
cd C:\Users\a321s\Desktop\zapret-discord-youtube-1.9.5

git remote add origin https://github.com/ВАШ_ЛОГИН/ИМЯ_РЕПО.git
git branch -M main
git push -u origin main
```

Пример для пользователя `ivan` и репозитория `zapret-discord-youtube`:

```bash
git remote add origin https://github.com/ivan/zapret-discord-youtube.git
git branch -M main
git push -u origin main
```

При первом `git push` браузер или Git запросят авторизацию на GitHub (логин/пароль или токен).

## 4. Если используете SSH

```bash
git remote add origin git@github.com:ВАШ_ЛОГИН/ИМЯ_РЕПО.git
git branch -M main
git push -u origin main
```

После этого репозиторий будет доступен по адресу  
`https://github.com/ВАШ_ЛОГИН/ИМЯ_РЕПО`.
