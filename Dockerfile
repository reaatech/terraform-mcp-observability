FROM docker:27-dind

RUN apk add --no-cache \
  nodejs=~20 \
  npm \
  curl \
  bash

RUN npm install -g pnpm@9

WORKDIR /workspace

COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile

COPY . .

CMD ["pnpm", "test"]
