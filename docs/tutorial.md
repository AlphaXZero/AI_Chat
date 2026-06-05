# Tutorial laravel + vue

This tutorial documents how the project is built, so it can be rebuilt from scratch anytime.

## Create the project

Create a new Laravel project:

```bash
laravel new project-name
```

During installation, choose the following options:

| Option | Choice |
|---|---|
| Starter kit | Vue |
| Authentication provider | Laravel |
| Testing framework | Pest |
| Laravel Boost | No |

Then install the front-end dependencies:

```bash
cd project-name
npm install
```

## Run the project

### Standard method

Start the back-end server (routes, API, database):

```bash
php artisan serve
```

In a second terminal, start the front-end server (asset compilation and hot reload):

```bash
npm run dev
```

### Quick method

A single command runs both the back-end and front-end at once:

```bash
composer run dev
```

The app is then available at `http://localhost:8000`.

> **Note:** In production, you don't run `npm run dev`. You compile the assets once with `npm run build`, and only the back-end runs (served by Nginx or Apache).



