# セキュリティで保護されたAPIの呼び出し

認証が必要なバックエンドAPIを呼び出すための設定をしていきます。
バックエンドAPIの認証は、Azure Functions/App Serviceで利用可能なEazyAuthの機能を利用します。

<img src="images/api-front-back-security-1.png" width=500px>

ここでやることは次のとおりです。

1. APIMのポリシーの設定(Json Web Tokenの検証)
2. JWTの検証のテスト
3. サンプルのAzure Functionの認証の設定
4. Azure Functionsの認証の動作確認
5. フロントエンドアプリのデプロイ
6. フロントエンドアプリのデプロイの認証の設定
7. フロントエンドアプリの認証の動作確認
8. フロントアプリにバクエンドへのアクセス権を付与
9. トラブルシューティング
10. APIMポリシーの設定更新
11. フロントエンドアプリからAPIMを経由して、バックエンドアプリを呼ぶ動作確認


## APIの設定

APIM のInbound Policyを設定し、期待するJava Web Tokenがリクエストヘッダに設定されている場合のみ、バックエンドのAPIを呼び出せるようにします。

### 1. APIMのポリシー設定(JWTの検証)

#### 1-1. Azureポータルで　APIMの管理画面を開く

#### 1-2. Inboundポリシーを追加

左Paneで「API」を選択しAll APIsから「Review」をクリックします。All Operationsが選択された状態で、Inbound processingセクションの「+ Add policy」をクリックします。

<img src="images/add-apim-policy-jwt-1.png">

#### 1-3. Validate JWTを選択
<img src="images/add-apim-policy-jwt-2.png" width="400px">

#### 1-4. ポリシーを設定

以下の値を入力し「Save」ボタンをクリックします。下記に記載のないパラメータはデフォルトのままでOKです。

> ここでは validate-jwt ポリシーの動作検証のためダミーの値を設定しています。

|名称|値|
|---|---|
|入力モード|Full|
|Validate By|Header|
|Header name|Authorization|
|Failed Validation HTTP code|401 - Unauthorized|
|Failed validation error message|Not Authorized|
|Issuer signing keys|123412341234123412341234|

<img src="images/add-apim-policy-jwt-3.png" width="400px">

#### 1-5. Review API の呼び出しでサブスクリプションを不要にする

左Paneで「API」を選択しAll APIsから「Review」をクリックし、Settingsセクションの「Subscription required」のチェックを外します。

### 2. JWT検証のテスト

#### 2-1. JWTなしでlistReviewsのテスト

テストタブを選択し、Operation一覧で「GET listReviews」を選択します。
「Send」ボタンをクリックし、401 Unauthorizedが返ってくることを確認します。

<img src="images/add-apim-policy-jwt-4.png" width="400px">


#### 2-2. JWTありでlistReviewsのテスト

Headerセクションの「+ Add Header」をクリックしてヘッダを追加します。

|名称|値|
|---|---|
|NAME|Authorization をプルダンで選択|
|VALUE|Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyLCJleHAiOjE4NjI4NDIzMDB9.nzqNkiuRD8EvG_QIwLmVogN-MCUlqAyOzYj679y7eHE|

「Send」ボタンをクリックして、200 OKが返ってくることを確認します。

<img src="images/add-apim-policy-jwt-5.png" width="400px">


#### Json Web Tokenの作り方
https://jwt.io/ でJWTを生成することができます。APIMのJWTの検証でエラーにならないように
* ペイロードに exp を追加 (01/11/2029 = 1862842300)
* シグネチャをbase64エンコード
が必要です。

<img src="images/add-apim-policy-jwt-6.png" width="400px">


## Azure Functionsの準備

### 3. サンプルのAzure Functionsの認証の設定

認証の設定をすると、Azure ADアプリケーション（サービスプリンシパルの一種）として登録されます。

※サービスプリンシパルは、Azureのリソースを操作するためのID

サービスプリンシパルの詳細については[アプリケーションとサービスプリンシパル](https://learn.microsoft.com/ja-jp/azure/active-directory/develop/app-objects-and-service-principals?tabs=browser#application-object)を参照してください。


#### 3-1. AzureポータルでサンプルのFunctionsの管理画面を開く

#### 3-2. 左Paneから「認証」を選択し、右Paneで「IDプロバイダの追加」をクリック
<img src="images/add-auth-func-1.png" width=400px>

#### 3-3. IDプロバイダのプルダウンメニューで「Microsoft」を選択

<img src="images/add-auth-func-2.png" width=400px>

#### 3-4. 認証の設定項目を入力

次の項目を入力し、「追加」ボタンをクリックします。


|名称|値|
|---|---|
|__基本タブ__|
|テナントの種類|従業員|
|__アプリの登録__|
|アプリの登録の種類|アプリの登録を新規作成する|
|名前|自動入力されている名称をそのまま利用|
|サポートされているアカウントの種類|現在のテナント-単一テナント|
|__App Service認証設定__|
|アクセスを制限する|認証が必要|
|認証されていない要求|HTTP 302 リダイレクトが見つかりました:Webサイトに推奨 <br>あとで、フロントアプリと連携する前にHTTP 401に変更します|
|トークンストア|デフォルトのまま（チェック）|

<img src="images/add-auth-func-3.png" width=400px>

### 4. Azure Functionsの認証の動作確認

#### 4-1. Azure Functionsの管理画面の左Paneで「関数」を選択し、右Paneで「listReviews」を選択

<img src="images/add-auth-func-4.png" width=300px>

#### 4-2. listReviewsのURLをコピー

右Pane上部の「関数のURLの取得」をクリックして、表示されたダイアログの左のプルダウンで「default(functio key)」を選択し、
テキストフィールドに表示された関数のURLをコピーします。

<img src="images/add-auth-func-5.png" width=300px>

#### 4-3. ブラウザのプライベートウィンドウを開き、コピーしたURLを貼り付けてlistReviewsを呼ぶ

Azure ADのサインインのダイアログが表示されるので、IDを入力して認証が正常するとlistReviewsの結果のJSONがブラウザに表示されます。

<img src="images/add-auth-func-6.png" width=200px>

<img src="images/add-auth-func-7.png" width=200px>


* 参考
    * https://learn.microsoft.com/ja-jp/azure/app-service/configure-authentication-provider-aad


## フロントアプリの準備

### 5. フロントアプリのデプロイ

#### 5-1. Azure Web Apps のデプロイ

フロントアプリを動作させるための Azure Web Apps をデプロイします。
Azure Cloud Shell を起動して、次のコマンドを実行します。
リソースグループ名（RG環境変数）やアプリケーション名（APP環境変数）の値は、自分の環境に合わせて変更してください。

```bash
export RG=apimdemo
export APP=frontappakubicharm

az appservice plan create -g $RG -n "${APP}-plan"
az webapp create -g $RG -n $APP -p "${APP}-plan" -r "java:17:Java SE:17"
```

#### 5-2. Azure Web Apps 構成設定

下記のように構成設定を行います。
APIM の名前(apimXX) や Functions の名前(backendappXX)の値は、自分の環境に合わせて変更してください。

|名前|値|
|---|---|
|JAVA_OPTS|-Dserver.max-http-header-size=30000|
|WEBSITES_PORT|8080|
|APIM_URL|APIMのGatewayのURL<br>例) `https://apimXX.azure-api.net`|
|FUNC_URL|FunctionsのURL<br>例) `https://backendappXX.azurewebsites.net`|

Cloud Shell から下記を実行します。

```bash
az webapp config appsettings set -g $RG -n $APP \
	--settings \
		JAVA_OPTS=-Dserver.max-http-header-size=30000 \
		WEBSITES_PORT=8080 \
		APIM_URL=https://apimXX.azure-api.net \
		FUNC_URL=https://backendappXX.azurewebsites.net
```

<!--
全般設定でBasic Authenticationをオンにする

<img src="images/frontapp-deploy-1.png" width="400px">
-->

#### 5-2. サンプルアプリケーションのデプロイ

フロントアプリのサンプルコードは [GitHub のレポジトリ](https://github.com/akubicharm/azure-apim-workshop-frontapp) にありますが、
ここではビルド済みの jar ファイルをデプロイするものとします。
Cloud Shell から下記を実行してください。

```bash
az webapp deploy --resource-group $RG --name $APP  --src-url https://github.com/akubicharm/azure-apim-workshop-frontapp/raw/main/artifact/demo-0.0.1-SNAPSHOT.jar   --type jar
```

### 6. フロントエンドアプリの認証の設定
Functionsと同様にEazy Authでの認証の設定をしていきます。


#### 6-1. AzureポータルでWeb App (フロントアプリ)　の管理画面を開く

#### 6-2. 左Paneから「認証」を選択し、右Paneで「IDプロバイダの追加」をクリック
<img src="images/add-auth-func-1.png" width=400px>

#### 6-3. IDプロバイダのプルダウンメニューで「Microsoft」を選択

<img src="images/add-auth-func-2.png" width=400px>

#### 6-4. 認証の設定項目を入力

次の項目を入力し、「追加」ボタンをクリックします。


|名称|値|
|---|---|
|__基本タブ__|
|テナントの種類|従業員|
|__アプリの登録__|
|アプリの登録の種類|アプリの登録を新規作成する|
|名前|自動入力されている名称をそのまま利用|
|サポートされているアカウントの種類|現在のテナント-単一テナント|
|__App Service認証設定__|
|アクセスを制限する|認証されていないアクセスを許可する|
|トークンストア|デフォルトのまま（チェック）|

<img src="images/add-auth-front-1.png" width=400px>


### 7. フロントアプリの認証の確認

#### 7-1. フロントアプリのURLを確認

Web Appの管理画面上部の規定のドメインに表示されているURLをコピーします。

<img src="images/add-auth-front-2.png" width=400px>


#### 7-2. 
デプロイしたアプリケーションにアクセスして、Log in のリンクをクリックする

<img src="images/add-auth-front-3.png" width=400px>


### 8. フロントエンドがバックエンド（Function）にアクセスするための設定

#### 8-1. フロントアプリのIDプロバイダ設定を表示

フロントアプリの管理画面の左Paneの「認証」をクリックして、認証設定画面を開きます。IDプロバイダセクションカラムのリンクをクリックして、設定画面を開きます。
<img src="images/add-auth-front-4.png" width=400px>

#### 8-2. APIアクセスの許可の設定

左Paneの「APIのアクセス許可」をクリックして、APIのアクセス許可の画面を開きます。
画面中央の「＋　アクセス許可の追加」ををクリックして、APIアクセス許可の要求ダイアログを開きます。
ダイアログ上部の「自分のAPI」タブを選択し、表示された一覧からバックエンドのFunctionアプリを選択します。

<img src="images/add-auth-front-5.png" width=500px>


#### 8-3. アプリケーションに必要なアクセス許可の種類の設定

委任されたアクセス許可を選択し、ダイアログ下部のuser_impersonationにチェックをして「アクセス許可の追加」をクリックします。

<img src="images/add-auth-front-6.png" width=500px>


#### 8-4. バックエンドアプリのスコープを確認

バックエンドアプリ（Functions)の管理画面の左Paneで「認証」をクリックし、画面中央のIDプロバイダの「編集」ボタンをクリックします。

<img src="images/add-auth-front-7.png" width=500px>

IDプロバイダの編集画面のアプリケーション（クライアント）IDをコピーしてメモ帳に貼り付けておきます。

<img src="images/add-auth-front-8.png" width=500px>

#### 8-5. クラウドシェルで設定を実行

```bash
authSettings=$(az webapp auth show -g [自分のリソースグループ] -n [フロントアプリの名前])
authSettings=$(echo "$authSettings" | jq '.properties' | jq '.identityProviders.azureActiveDirectory.login += {"loginParameters":["scope=openid offline_access api://[コピーしたアプリケーション（クライアント)ID]/user_impersonation"]}')
az webapp auth set --resource-group [自分のリソースグループ] --name [フロントアプリの名前] --body "$authSettings"
```

例）
```bash
authSettings=$(az webapp auth show -g apimdemo -n frontappakubicharm)
authSettings=$(echo "$authSettings" | jq '.properties' | jq '.identityProviders.azureActiveDirectory.login += {"loginParameters":["scope=openid offline_access api://325510f9-bd47-4830-9fba-84188014eb7e/user_impersonation"]}')
az webapp auth set --resource-group apimdemo --name frontappakubicharm --body "$authSettings"
```
#### 8-6. フロントエンドアプリとバックエンドの動作確認

フロントエンドアプリをブラウザのシークレットモードで開き「Log in」のリンクをクリックしてAzure ADで認証します。
その後、「レビューのFunction直接呼び出し」のリンクをクリックし、商品レビューの一覧が表示されることを確認します。

> ここではフロントアプリ（Web Apps）からバックエンド API（Functions） を直接呼び出しているため、API Management を経由していません。

#### 8-7. フロントエンドアプリのログとデバッグ

フロントエンドアプリの動作確認でエラーが発生した場合には、ログストリームやソースコード（[HtmlController.kt](https://github.com/akubicharm/azure-apim-workshop-frontapp/blob/main/src/main/kotlin/com/example/demo/controller/HtmlController.kt) の `gutFunc` メソッド）を確認してみてください。

- Azure ポータルで Web Apps の管理画面を開く
- 左 Pane の「App Service ログ」をクリック
    - アプリケーションのログ記録（ファイルシステム）を「オン」にする
    - 「レベル」ドロップダウンで「詳細」を選択
    - 「保存」ボタンをクリック
- 左 Pane の「ログ ストリーム」をクリック
    - 「Welcome, you are now connected to log-streaming service.」が表示されるのを待つ
    - この画面を表示したままで前述の動作確認（シークレットモードで開いているブラウザ）を行う

### 9. トラブルシューティング : 管理者またはユーザの同意が必要です
フロントアプリケーションのログイン時に「管理者またはユーザの同意が必要です」となった場合は、バックエンドアプリの承認されたクライアントアプリケーションとして登録する必要があります。

<img src="images/add-auth-front-9.png" width=300px>

####　9-1. バックエンドアプリケーションのIDプロバイダ設定を開く

バックエンドアプリ(Functions)の管理画面の左Paneで「認証」をクリックし、右PaneのIDプロバイダのリンクをクリックしてIDプロバイダの管理画面を表示します。

<img src="images/add-auth-front-10.png" width=300px>

#### 9-2. バックエンドアプリの承認済みクライアントとしてフロントエンドアプリのアプリケーション(クライアント)IDを登録

左Paneで「APIの公開」を選択し、右Paneで「＋　クライアントアプリケーションの追加」をクリックします。

<img src="images/add-auth-front-10.png" width=500px>

#### 9-3. クライアントアプリケーションの追加

表示されたクライアントアプリケーションの追加ダイアログに以下を入力し、「アプリケーションの追加」ボタンをクリックします。

|名称|値|
|---|---|
|クライアントID|フロントアプリケーションのアプリ(クライアント)ID
|承認済みのスコープ|チェック|

クライアントIDは、フロントアプリ(Web App)の管理画面の左Paneで「認証」を選択し、右Paneの中央あたりに表示された「アプリ（クライアント）ID」をコピーする

<img src="images/add-auth-front-12.png" width=400px>


### 10. APIMのポリシーの更新

バックエンドの API の認証設定により、Azure AD で認証済みのユーザーおよびアプリケーションのみがバックエンド API をコールできるようになっています。
ここでは Web Apps で動作しているフロンエンドアプリのみがバックエンドの API をコールできるように、APIMのJson Web Tokenの検証ポリシーを更新します。

#### 10-1. トークン対象ユーザの確認とOpenID URlの確認

フロントアプリ(Web App)の管理画面の左Paneで「認証」を選択し、右PaneのIDプロバイダの編集の鉛筆アイコンをクリックします。

許可されるトークン対象ユーザをメモ帳などにコピーしておきます。
確認したら、右上の「×」をクリックして「IDプロバイダの編集」画面を閉じ、フロントアプリの管理画面に戻ります。

<img src="images/apim-jwt-policy-2.png" width=300px>

IDプロバイダのリンクをクリックします。

<img src="images/apim-jwt-policy-3.png" width=300px>


開いた認証画面の上部の「エンドポイント」をクリックして、エンドポイントのダイアログを開き「OpenID Connect メタデータドキュメント」をコピーしてメモ帳などに貼っておきます。

<img src="images/apim-jwt-policy-4.png" width=500px>

同じようにバックエンドアプリ（Functions）の管理画面から、トークン対象ユーザーをメモ帳などにコピーしておきます。
「OpenID Connect メタデータドキュメント」 はフロントアプリと共通です。

#### 10-2. validate-jwt ポリシーの編集

APIMの管理画面の左Paneで「API」を選択し、API一覧で「Review」を選択します。
Inbound processingの「validate-jwt」の右の鉛アイコンをクリックして編集します。

<img src="images/apim-jwt-policy-5.png" width=500px>

※ 「validate-jwt」をクリックするとコードでの編集モード、鉛筆アイコンをクリックするとフォームでの編集モードになります。

#### 10-3. 最初に設定した Issuer signing keysの値の右のゴミ箱アイコンをクリックして値を削除します。

#### 10-4. フロントアプリからの呼び出してあることを検証

Required claimsの「+ Add claim」をクリックをしてclaimの設定をします。

|名称|値|
|---|---|
|Name|appid|
|Match|Any claim|
|Separator|デフォルトのまま|
|Values|コピーしておいたトークンの対象ユーザの GUID 部分<br>例) aaaaaaaa-bbbb-cccc-dddd-000000000000|

#### 10-5. バックエンドアプリのアクセス許可を持っていることを検証

「Audiences」にバックエンドアプリ（Functions）の管理画面からコピーしておいたトークンの対象ユーザを入力

例）api://xxxxxxxx-yyyy-zzzz-wwww-000000000000

#### 10-6. OpenID Connect メタデータドキュメントを設定

OpenID URlsの「+ Add OpenID URL」をクリックして、コピーしておいたOpenID URLの **バージョン番号部分を除去したもの**を貼り付けます

- コピーした値の例
    - `https://login.microsoftonline.com/16b3c013-d300-468d-ac64-7eda0820b6d3/v2.0/.well-known/openid-configuration`
- 入力する値の例
    - `https://login.microsoftonline.com/16b3c013-d300-468d-ac64-7eda0820b6d3/.well-known/openid-configuration`


<img src="images/apim-jwt-policy-6.png" width=300px>


画面下部の「Save」ボタンをクリックしてvalidate-jwtポリシーを保存します。

### 10-7. validate-jwt ポリシーの設定内容

上記の手順で設定された validate-jwt ポリシーを コード形式（XML）で確認すると以下のようになります。
各項目の意味は [ポリシーリファレンス](https://learn.microsoft.com/ja-jp/azure/api-management/validate-jwt-policy) のドキュメントで確認してみてください。

```xml
<validate-jwt header-name="Authorization" failed-validation-httpcode="401" failed-validation-error-message="Not Authorized...">
    <openid-config url="https://login.microsoftonline.com/16b3c013-d300-468d-ac64-7eda0820b6d3/.well-known/openid-configuration" />
    <audiences>
        <audience>api://xxxxxxxx-yyyy-zzzz-wwww-000000000000</audience>
    </audiences>
    <required-claims>
        <claim name="appid" match="any">
            <value>aaaaaaaa-bbbb-cccc-dddd-000000000000</value>
        </claim>
    </required-claims>
</validate-jwt>
```

### 11. フロントエンドアプリからAPIMを経由して、バックエンドアプリを呼ぶ動作確認

#### 11-1. フロントエンドアプリをブラウザのプライベートモードで開く

#### 11-2. Log InリンクをクリックしてAzur ADでログイン

#### 11-3. 「レビューのAPI呼び出し」のリンクをクリック

レビュー一覧が表示されることを確認します。


* 参考
    * https://learn.microsoft.com/ja-jp/azure/app-service/tutorial-auth-aad?pivots=platform-linux

#### 11-4. トラブルシュート

フロントエンドアプリでのサインイン（Log In リンクのクリック）で取得したアクセストークンは Web Apps の[トークンストア](https://learn.microsoft.com/ja-jp/azure/app-service/configure-authentication-oauth-tokens)に格納されています。
- サーバーサイドでは `x-ms-token-aad-access-token` リクエストヘッダーから取得できます
    - [HtmlController.kt](https://github.com/akubicharm/azure-apim-workshop-frontapp/blob/main/src/main/kotlin/com/example/demo/controller/HtmlController.kt) の `guReview` メソッドを参照すると、トークンの値がログ出力されているため ログ ストリーム で値が確認できます
    - この値は API Management リクエスト時に Authorization ヘッダーに設定して送信されています
- クライアントサイド（ブラウザ）では `/.auth/me` エンドポイントからも値が確認できます
    - 別タブで `https://[フロントエンドアプリのURL]/.auth/me` を開くと JSON が表示されます

ここで確認したアクセストークンの値を https://jwt.ms などでデコードして、validate-jwt ポリシーの設定値と一致しているか確認してみましょう。

<!--
JWTの確認機能

https://learn.microsoft.com/ja-jp/azure/api-management/api-management-howto-protect-backend-with-aad
テストするためには、ADで取得したトークンが必要なので、開発者ポータルでやる感じ。 このドキュメントはOAuth2になっているけど、ここをOpenID Connectにしても可能
https://learn.microsoft.com/ja-jp/azure/api-management/api-management-howto-oauth2


IDトークンの話
https://learn.microsoft.com/ja-jp/azure/active-directory/develop/id-tokens


フロントアプリからのトークンの渡し方かも
https://learn.microsoft.com/ja-jp/azure/app-service/tutorial-auth-aad?pivots=platform-linux
-->