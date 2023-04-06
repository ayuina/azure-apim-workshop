# Azure Functionとの連携

API Managementを通してAzure Functionを呼び出すための設定をしていきます。


Azure Function連携でやることは次のとおりです

1. デモ用Azure Functionsのデプロイ
2. APIを追加
2. Operationの定義
3. 関数 putFileの呼び出しのテスト


## Azure Functions をデプロイ

#### 1. このボタンをクリックして、APIM のデプロイを開始　<a href="https://portal.azure.com/#create/Microsoft.FunctionApp"><img src="./images/deploytoazurebutton.svg" /></a>　


#### 2. 基本タブ
|__名称__|__値__|
|---|---|
||__プロジェクト詳細__|
|サブスクリプション| ハンズオンで利用するサブスクリプションを選択||
|リソースグループ|ハンズオンで利用するリソースグループを選択。新規作成する場合は、「新規作成」をクリックしてリソースグループを入力<br><br><img alt="リソースグループの新規作成" src="images/new-rg.png" width="400px"> |apimws|
|__インスタンス詳細__|
|関数アプリ名|関数アプリ名を入力。このリソース名がドメイン名の元になるので、Azure上で一意となる名称。<br>例)apimfunc20230401、mynamefuncws<br>ドメイン名の例）apimfunc20230401.azurewebsites.net|
|公開|コードにチェック|
|ランタイムスタック|Node.js|
|バージョン|18LTS|
|地域|ハンズオンで利用するリージョンを選択。例）Japan East|
|__オペレーティングシステム__||
|オペレーティングシステム|Linuxにチェック|
|__プラン__||
|プランの種類|消費量（サーバーレス）|

画面下部の「確認および作成」ボタンをクリック