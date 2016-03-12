WebView
A Porta de entrada pra o desenvolvedor web

- Introdução

Aqui eu coloco a visão de um profissional de aplicativos, que também já programou para web, mas em um tempo que a a Stack não estava tão profissionalizada, o termo webmaster era usado no lugar de front-end engineer + backend-engeneer. Trabalho com desenvolvimento iOS a 2 anos e nesse período participei de dois projetos que foi necessário criar uma App que seria uma "casca" para um site. E o interessante e que nos dois casos os requisitos não ficaram apenas no abertura do site simplesmente, o site deveria interagir a parte nativa do aplicativo, ou seja, o código do site e do app deveria conversar.

- Ponte de comunicação Javascript/Objective-C

O premeiro desafio é fazer essa conversa acontecer, a velha UIWebView não apresenta uma forma objetiva de executar javascript, e dessa forma nada de conversa fácil ente código nativo e Javascript. 
 - ObjC to JS
Para enviar um javascript para a página abertar será necessário incluir o código no método 'webView: shouldStartLoadWithRequest: navigationType:' assim antes do carregamento da página é possível incluir no seu contexto qualquer código JS.

```objc
- (void)injectJavascript:(NSString *)resource {
    NSString *jsPath = [[NSBundle mainBundle] pathForResource:resource ofType:@"js"];
    NSString *js = [NSString stringWithContentsOfFile:jsPath encoding:NSUTF8StringEncoding error:NULL];
    
    [self.uiWebView stringByEvaluatingJavaScriptFromString:js];
}
-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType{
    
    [self injectJavascript:@"scripts"];

    return YES;

}
```

 - JS to ObjC
O inverso não é tão simples, não é possível chamar o código ObjC diretamente, é preciso estabelecer um protocolo de comunicação via url, por exemplo: JStoObjC://title=equinociOS.
Esse padrão deverá ser identificado no mesmo método 'webView: shouldStartLoadWithRequest: navigationType:' e aí sim executar o código nativo.

```objc
-(BOOL)isJStoObjcSchema:(NSString *)url{
    return [url rangeOfString:@"JStoObjC://"].location != NSNotFound;
}
-(NSString *) titleWithUrl:(NSString *)url{
    NSString *title;
    NSArray *urlParts = [url componentsSeparatedByString:@"="];
    if (urlParts) {
        title = urlParts[1];
        title = [title stringByRemovingPercentEncoding];
        
    }
    return title;
}
-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType{
    
    NSString *absoluteUrl = [request URL].absoluteString;
    
    if([self isJStoObjcSchema:absoluteUrl]){
        self.navigationItem.title = [self titleWithUrl:absoluteUrl];
        return NO;
    }
    
    [self injectJavascript:@"scripts"];
    NSLog(@"shoulrStart: %@",[request URL]);
    return YES;
}
```

O Projeto 'WebViewJavascriptBridge' de 'Marcus Westin' faz o trabalho descrito acima de uma maneira genérica permitindo a execução dos scripts a qualquer momento.

O formato acima só seria mandatório para atender a ~6% de base de dispositivos que ainda rodam o iOS7, entretanto para os dispositivos com as versões do iOS 8+ está disponível a WebKit WebView, que é inclusivel uma recomendação de uso da Apple para essas versões de iOS. A comunicação Javascript/Código Nativo já está em um nível bem superior.

-JStoObjC
[código]

-ObjeCtoJS
[código]

- Trabalhando com Cookies

Mas nem tudo são flores, o WebView do WebKit não consegue usar de forma satisfatória o 'NSHTTPCookieStorage', e nesse caso o potencial Javascript deve ser utilizado no processo de manipulação de cookies. Caso o seu projeto tenha por exemplo, um login nativo e que precise passar o token para a página para manar o usuário logado na web você vai precisar escrever, deletar ou ler cookies da Webview. 
Começando com a UIWebView, a manipulação de cookies se dá de forma muito eficiente utilizando o 'NSHTTPCookieStorage'.

 - Gravando um Cookie
```objc
-(void)saveCookie:(NSString *)key value:(NSString *)value{
    NSMutableDictionary *cookieProperties = [NSMutableDictionary dictionary];
    [cookieProperties setObject:key forKey:NSHTTPCookieName];
    [cookieProperties setObject:value forKey:NSHTTPCookieValue];
    [cookieProperties setObject:@"equinocios.com" forKey:NSHTTPCookieDomain];
    [cookieProperties setObject:@"equinocios.com" forKey:NSHTTPCookieOriginURL];
    [cookieProperties setObject:@"/" forKey:NSHTTPCookiePath];
    [cookieProperties setObject:@"0" forKey:NSHTTPCookieVersion];
    
    NSHTTPCookie *cookie = [NSHTTPCookie cookieWithProperties:cookieProperties];
    [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:cookie];

}
```

 - Deletando um Cookie 
 ```objc
-(void)deleteCookie:(NSString *)key{
    NSHTTPCookieStorage *storage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    for (NSHTTPCookie *cookie in [storage cookies]) {
        if ([cookie.name isEqualToString:key]) {
            [storage deleteCookie:cookie];
        }
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
}
 ```

 - Obtendo um Cookie
```objc
-(NSString *)cookie:(NSString *)key{
    NSArray *httpCookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies];
    for (NSHTTPCookie *cookie in httpCookies) {
        if([[cookie name] isEqualToString:key]){
            return [cookie value];
        }
    }
    return nil;
}
``` 

Já para Manipular o cookie na WK precisaremos trabalhar com uma implementação javascript, vejo isso como um benefício já que o time de web poderá fazer implementações otimizadas de acordo com sua necessidade. Para criar um cookie é necessário que, além de executar o script de criação do Cookie, que página seja carregada na sua totalidade para que o cookie seja criado/deletado efetivamente.

[código]

- Cache e Performance

Nesse ponto que as coisas começam a complicar, o que se espera de um aplicativo é que seja performático e uma webview nem sempre entrega isso de forma aceitável, caso seu conteúdo seja complexo, com muitas imagens, fontes customizadas, chamadas ajax etc isso tende a degradar o carregamento das páginas e não haverá cache que ajudará um segundo carregamento, já que além da obtenção dos dados o que torna uma página web rápida é também como ela foi construída. 
A política de cache padrão de um request é a 'NSURLRequestUseProtocolCachePolicy' a imagem a baixo (obtida da própria referência da apple) descreve seu comportamente. Existem algumas outras políticas de para os diversos casos: Cache parcial sem cache etc.

 - Request com política de Cache
 ```objc
 -(void)loadWKWebViewWithUrl:(NSString *)absoluteUrl{
    NSURL *url = [NSURL URLWithString:absoluteUrl];
    NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:1.0];
    [_wkWebView loadRequest:request];
}
 ```

No caso de utilização de webview é notório o consumo de memória, em específico da UIWebView em iOS 8+, e limpar o cache em caso de MemoryWarning ajudará a manter o bom funcionamento do seu aplicativo.

"In apps that run in iOS 8 and later, use the WKWebView class instead of using UIWebView. Additionally, consider setting the WKPreferences property javaScriptEnabled to false if you render files that are not supposed to run JavaScript." UIWebView Reference

 - Limpar cache
 ```objc
 - (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
    [[NSURLCache sharedURLCache] setDiskCapacity:0];
    [[NSURLCache sharedURLCache] setMemoryCapacity:0];
}
 ``` 

E mesmo que a escolha seja a de colocar o html embarcado ele ainda terá o passo atrás de renderizar HTML+CSS+Javascript e não uma View da plataforma.

```objc
-(void)loadUIWebViewWithLocalData{
    NSString *htmlFile = [[NSBundle mainBundle] pathForResource:@"index" ofType:@"html"];
    NSString* htmlString = [NSString stringWithContentsOfFile:htmlFile encoding:NSUTF8StringEncoding error:nil];
    [self.uiWebView loadHTMLString:htmlString baseURL:[NSURL URLWithString:@"http://equinocios.com"]];
}
```

- Performance do HTML
Preocupar-se com a performance do código web para uma webview é ainda mais relevante além de ela ser uma versão piorada do navegador, estarmos em um dispositívo que precisa otimizar o consumo de bateria em alguns momentos. Então burbinar seu código vai ajudar substancialmente a sua webview rodar suave. A idéia que o código seja escrito de maneira minimizar reflows e repaints e obviamente scripts que bloqueiem a interação do usuário.

https://www.youtube.com/watch?v=ZTnIxIA5KGw

- Performance
Embora a WKWebView tenha sido lançada com o iOS8 em 2014 o Google Chrome por exemplo só foi adotá-la no início desse ano e só usa para iOS9+. E como era de se esperar a diferença de performance é gritante. Segue abaixo um comparativo da UIWebView vs WKWebView. Um dos motivos que foi citado pelo google pra não utilização do WK é não ter um caminho obvio para gerenciar cookies.

[Chrome-48-for-iOS.001-640x470]

[vídeo]

- Ferramentas de inspeção
E para um desenvolvedor web treinada nada é mais fundamental do que o inspect do navegador, e para a webview isso continua igual, obviamente que é a ferramenta do Safari. E de simples utilização, basta habilitar o modo desenvolvedor do Safari e o menu desenvolvedor ficará disponível.

[Imagens]

- Browser inApp.
E para os aplicativos que querem manter seu usuário ainda no contexto do seu aplicativo já que está disponível para iOS9+ o Safari View Controler. A SafariView controler apresenta a experiência consistente com o próprio safari levando o autopreenchimento de formulários cookies, ou seja se o usuário logou no safari e estará logado na safari view controller.

```objc
-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType{
    
    NSString *absoluteUrl = [request URL].absoluteString;
    
    if([self isJStoObjcSchema:absoluteUrl]){
        self.navigationItem.title = [self titleWithUrl:absoluteUrl];
        return NO;
    }
    
    if (![self isInnerURL:absoluteUrl] && navigationType == UIWebViewNavigationTypeLinkClicked) {
        SFSafariViewController *svc = [[SFSafariViewController alloc]initWithURL:request.URL];
        [self presentViewController:svc animated:YES completion:^{
            
        }];
        return NO;
    }
    
    [self injectJavascript:@"ui_script"];
    return YES;
}
```

- Conclusão

Entenda que se utilizar conteúdo web ou mesmo um site dentro de um aplicativo você deve esperar um comportamento de browser e não de aplicativo. A Webview é como um motor de uma equipe menor da formula 1, o Safari sempre terá o motor do ano, e difícilmente a performance da webview superará o browser. Tomados esse cuidados um aplicativo feito na webe pade apresentar experiência fantástica para o usário e ajudar um time que seja focado em web a prepara um aplicativo sem maiores problemas.

- Agrdecimentos

Agradeço Sohorio pela inciativa do projeto do EquinociOS e a todos os membros da comunidade do cocoaheads que prontamente absorveu a sugestão e em poucos dias já estavam com tudo preparado para o mês de março e seus 20 artigos planejados mais extras. Pra mim é um previlégio.

- Referências
AppStore - https://developer.apple.com/support/app-store/
WebViewJavascriptBridge - https://github.com/marcuswestin/WebViewJavascriptBridge
NSHTTPCookieStorage - https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSHTTPCookieStorage_Class/
Minimizing browser reflow - https://developers.google.com/speed/articles/reflow#guidelines 
Rendering: repaint, reflow/relayout, restyle - http://www.phpied.com/rendering-repaint-reflowrelayout-restyle/
Using JavaScript with WKWebView in iOS 8 -http://www.joshuakehn.com/2014/10/29/using-javascript-with-wkwebview-in-ios-8.html
A faster, more stable Chrome on iOS - http://blog.chromium.org/2016/01/a-faster-more-stable-chrome-on-ios.html
Use WKWebView on iOS 9+ - https://bugs.chromium.org/p/chromium/issues/detail?id=423444

Esse é mais um assunto que diz respeito a todas as plataformas, duas dessas eu tenho um contato maior, que são Android e obviamente o iOS. Quando se pensa em desenvolver com uma estrutura unificada nada mais natural para um time que pensar em continuar fazendo isso pra web. E isso é perfeitamente possível. Continuar no app uma experiência que é bem sucedida da web.

Para um desenvolvedor web, uma app é um site são a mesma coisa em questão de performance, ou seja, um usuário leito não saberia identificar o que é o que, e de certa forma um leigo não seria capaz de apontar um ou outro. Mas não se trata disso, se trata do cenário, se tivermos falando de um conteúdo complexo, um aplicativo tem um trabalho de renderizar na tela a uma taxa de 60 frames por sengundo o que foi desenhado pelo desevolvedor, em uma webview as coisas são diferentes, o processo de renderização de um html baseado em sua forlha de estilos em castaca torna a renderização web, mesmo que bem otimizada um passo atrás do nativo, por que ele tem um processo de reflow e repaint, ou seja, quando se decidi fazer uma app com webview você está lutando contra a expectativa do usuário, e contra a tecnologia. O usuário sempre espera uma performance melhor de uma App, quando ele está no navegador ele já entendo que ele chamará uma página e ela vai ficar ali alguns segundos se ajeitando da ali e de lá.

A UIWebview está presente desde d versão 2 da SDK,