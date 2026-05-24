# boot_aop

AOP (Aspect-Oriented Programming) support for the Boot Framework.

## Features

- `@Around` — marks an annotation as AOP advice
- `@InterceptorBean` — links interceptor to annotation
- `InterceptorChain` — chains multiple interceptors
- `InvocationContext` — method name, args, target, proceed()

## Usage

```dart
@Around()
class Timed { const Timed(); }

@InterceptorBean(Timed)
class TimedInterceptor implements MethodInterceptor {
  dynamic intercept(InvocationContext ctx) {
    final sw = Stopwatch()..start();
    final result = ctx.proceed();
    sw.stop();
    print('${ctx.methodName} took ${sw.elapsedMilliseconds}ms');
    return result;
  }
}
```
