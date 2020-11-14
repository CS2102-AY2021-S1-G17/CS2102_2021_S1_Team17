Demo video [here](https://youtu.be/Jh4bKPk7zmY)

Heroku page [here](https://cs2102-petcare.herokuapp.com/)

## Getting started
1. Create a database by running `CREATE DATABASE petcare` in sql terminal.
2. Create a file `.env` under the root directory for database setup. 

    Content of the file: 
    ```
    DATABASE_URL=postgres://[:username]:[:password]@localhost:5432/petcare
    SECRET=catcat
    ```
    [:username]: replace with database username \
    [:password]: replace with database password

3. In sql terminal, run \i path/to/file/sql/init.sql to execute `sql/init.sql` file.
4. Run `npm install` to install packages and dependencies.
5. Run `npm start`, open a browser and go to  `localhost:3000`.\
In development mode, run `nodemon start` to avoid restart server after making changes.
