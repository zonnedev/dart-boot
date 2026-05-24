FROM dart:3.12 AS build
WORKDIR /app
COPY pubspec.yaml pubspec.lock ./
RUN dart pub get
COPY . .
RUN dart run build_runner build --delete-conflicting-outputs
RUN dart compile exe bin/main.dart -o /app/server

FROM scratch
COPY --from=build /runtime/ /
COPY --from=build /app/server /app/server
COPY --from=build /app/application.yml /app/application.yml
WORKDIR /app
EXPOSE 8080
ENTRYPOINT ["/app/server"]
