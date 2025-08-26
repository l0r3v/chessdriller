FROM "node:alpine"

WORKDIR /code

RUN apk add --no-cache libc6-compat bash openssl

COPY package.json .

RUN npm install

COPY . .

RUN npx prisma generate
RUN npx prisma db push 
RUN npm run build

EXPOSE 3123

CMD ["node", "server.js"]
