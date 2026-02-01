FROM node:22.21.1-alpine AS base
WORKDIR /usr/src/wpp-server

# Evita descargar Chromium de Puppeteer (usaremos el del sistema)
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium-browser
ENV CHROME_BIN=/usr/bin/chromium-browser

# Dependencias de build + runtime
RUN apk update && apk add --no-cache \
    vips vips-dev fftw-dev \
    gcc g++ make libc6-compat pkgconfig python3 \
    chromium \
    nss freetype harfbuzz ttf-freefont \
    && rm -rf /var/cache/apk/*

# To make sure yarn 4 uses node-modules linker
COPY .yarnrc.yml ./
COPY package.json ./
COPY yarn.lock ./

RUN corepack enable && corepack prepare yarn@4.12.0 --activate
RUN yarn install --immutable

FROM base AS build
WORKDIR /usr/src/wpp-server
COPY . .
RUN yarn build

FROM base AS runtime
WORKDIR /usr/src/wpp-server
COPY --from=build /usr/src/wpp-server/dist ./dist
COPY --from=build /usr/src/wpp-server/node_modules ./node_modules
COPY --from=build /usr/src/wpp-server/package.json ./package.json
COPY --from=build /usr/src/wpp-server/.yarnrc.yml ./.yarnrc.yml

EXPOSE 21465
ENTRYPOINT ["node", "dist/server.js"]
