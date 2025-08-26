FROM "node:alpine"

WORKDIR /code

COPY package.json .

RUN npm install

COPY . .

RUN npx prisma db push 
RUN npm run build

EXPOSE 3123

CMD ["node", "server.js"]
