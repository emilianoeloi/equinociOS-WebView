WebView
A Porta de entrada pra o desenvolvedor web

- Introdução

Aqui eu coloco a visão de um profissional de aplicativos, que também já programou para web, mas em um tempo que a a Stack não estava tão profissionalizada, o termo webmaster era usado no lugar de front-end engineer + backend-engeneer. Trabalho com desenvolvimento iOS a 2 anos e nesse período participei de dois projetos que foi necessário criar uma App que seria uma "casca" para um site. E o interessante e que nos dois casos os requisitos não ficaram apenas no abertura do site simplesmente, o site deveria interagir a parte nativa do aplicativo, ou seja, o código do site e do app deveria conversar.

- Ponte de comunicação Javascript/Objective-C

O premeiro desafio é fazer essa conversa acontecer, a velha UIWebView não apresenta uma forma objetiva de executar javascript, e dessa forma nada de conversa fácil ente código nativo e Javascript. 
 - ObjC to JS
Para enviar um javascript para a página abertar será necessário incluir o código no método 'webView: shouldStartLoadWithRequest: navigationType:' assim antes do carregamento da página é possível incluir no seu contexto qualquer código JS.

```Javascript
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

```Javascript
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

- Gerenciando Cookies

Mas nem tudo são flores, o WebView do WebKit não consegue usar de forma satisfatória o 'NSHTTPCookieStorage', e nesse caso o potencial Javascript deve ser utilizado no processo de manipulação de cookies.
Começando com a UIWebView, a manipulação de cookies se dá de forma muito eficiente utilizando o 'NSHTTPCookieStorage'.

[código]

Já para Manipular o cookie na WK precisaremos trabalhar com uma implementação javascript, vejo isso como um benefício já que o time de web poderá fazer implementações otimizadas de acordo com sua necessidade. Para criar um cookie é necessário que, além de executar o script de criação do Cookie, que página seja carregada na sua totalidade para que o cookie seja criado/deletado efetivamente.

[código]

- Cache e Performance

Nesse ponto que as coisas começam a complicar, se seu conteúdo for muito grande e complexo, um exemplo disso é um feed de notícias com muitas imagens, processamento, chamadas ajax, não haverá cache que ajudará um segundo carregamento, já que para uma página web não é apenas a obtenção dos dados que a tornará de rápido carregamento. Para um desenvolvedor web, uma app é um site são a mesma coisa em questão de performance, ou seja, um usuário leito não saberia identificar o que é o que, e de certa forma um leigo não seria capaz de apontar um ou outro. Mas não se trata disso, se trata do cenário, se tivermos falando de um conteúdo complexo, um aplicativo tem um trabalho de renderizar na tela a uma taxa de 60 frames por sengundo o que foi desenhado pelo desevolvedor, em uma webview as coisas são diferentes, o processo de renderização de um html baseado em sua forlha de estilos em castaca torna a renderização web, mesmo que bem otimizada um passo atrás do nativo, por que ele tem um processo de respan e repaint, ou seja, quando se decidi fazer uma app com webview você está lutando contra a expectativa do usuário, e contra a tecnologia. O usuário sempre espera uma performance melhor de uma App, quando ele está no navegador ele já entendo que ele chamará uma página e ela vai ficar ali alguns segundos se ajeitando da ali e de lá.

[Código]

Mesmo que escolhamos a opção de colocarmos o html embarcado ele ainda terá o passo atrás de renderizar HTML+CSS+Javascript e não uma View da plataforma.

[Código]

E mesmo assim existem algumas políticas de cache para cada caso. SEm cache, com cache.. com cache parcial...

[Código]

- Performance do HTML
Queria escrever um pequeno parágrafo falando especificamente de otimização web, que se trata de entender como o CSS trabalha, isso vai ajudar substancialmente a sua webview rodar suave e fazer com que o usuário não se frente com o velocidade. a idéia é que todo o CSS sejá escrito de maneira a que ele precise fazer o repaint da página o mínimo possível já que estamos falando de um hardare que é muito super-estimado, no fim o harduware de um telefone, mesmo um high-end não se compara a um desktop, ou seja, a otimização feita pra desktop muitas vezes não é o suficiente para o iphone/ipad etc. Segue uma imagem de descreve como a web entende e renderiza os estilos.

[image]

[código]

- Performance
Bem vamos falar da webview, segue abaixo um comparativo da UIWebView no iOS8/iPhone6Plus e o WKWebView/iPhone5 a própria apple recomenda a utlização da WKWebView a partir do iOS8, mas os problemas de cookie fizeram até mesmo o Google não utilia a WK no Chrome, eles descrevem que é por conta da manipulação de cookies. Eu estou com a apples, eu utilizo a WK na maioria das vezes e sei que vou ter a melhor performance que é o que eu acredito ser fundamenta para que o usuário tenha a melhro experiência.

[Código]

[Imagem]

- Ferramentas de inspeção
E para o desenvolvedor web treinada nada é mais fundamental do que o inspect do navegador, e para a webview isso continua igual, obviament que o inspect será do safari. E de simples utilização, mas ta habilitar o modo desenvolvedor do Safaria e esse ítem de menu sará habilitado, daí o inspect segue da mesma maneira que se faz no safari.

[Imagens]

- Não preciso de Webview.
Para o iOS9 essa afirmativa correta, já que está disponível para essa versão do sistema operacional o Safari View Controler. Caso você só precise abrir um link qualquer inApp ou mesmo aproveitar para que o usuário permaneça na sua App esse solução é inclível, porque além de ela ter uma experiencia visual padronizada, ela também compartilha resources com o Safari que o usuário já usa no dia a dia. E se já é uma ViewController já sabemos que é de muitao simples implementação:

[Código]

Browser

Entenda que se utilizar conteúdo web ou mesmo um site dentro de um aplicativo você deve esperar um comportamento de browser e não de aplicativo. A Webview é como um motor de uma equipe menor da formula 1, o Safari sempre terá o motor do ano, e difícilmente a performance da webview superará o browser. Tomados esse cuidados um aplicativo feito na webe pade apresentar experiência fantástica para o usário e ajudar um time que seja focado em web a prepara um aplicativo sem maiores problemas.

- Agrdecimentos

Agradeço Sohorio pela inciativa do projeto do EquinociOS e a todos os membros da comunidade do cocoaheads que prontamente absorveu a sugestão e em poucos dias já estavam com tudo preparado para o mês de março e seus 20 artigos planejados mais extras. Pra mim é um previlégio.

- Referências
AppStore - https://developer.apple.com/support/app-store/ - acessado em 12/03/2016
WebViewJavascriptBridge - https://github.com/marcuswestin/WebViewJavascriptBridge - acessado em 12/03/2016

Esse é mais um assunto que diz respeito a todas as plataformas, duas dessas eu tenho um contato maior, que são Android e obviamente o iOS. Quando se pensa em desenvolver com uma estrutura unificada nada mais natural para um time que pensar em continuar fazendo isso pra web. E isso é perfeitamente possível. Continuar no app uma experiência que é bem sucedida da web.

A UIWebview está presente desde d versão 2 da SDK,