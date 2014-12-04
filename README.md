# cobudget landing

landing page for the [cobudget app](https://github.com/open-app/cobudget)

## how to

### install

```
git clone https://github.com/derekrazo/cobudget-landing
cd cobudget-landing
npm install
```

### start

will build once and start a static server

```
npm start
```

### develop

will build on watch and start a livereload server

```
npm run develop
```

### stage

will build once and deploy to gh-pages

```
NODE_ENV=production npm run stage
```

### deploy

add `deploy` remote repo

```
git remote add deploy dokku@next.cobudget.co:landing
```

will build once and deploy to dokku

```
NODE_ENV=production npm run deploy
```
