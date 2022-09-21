# VaultAPI

The [VaultAPI](https://apilayer.com/marketplace/vault-api) is a "_Full featured encrypted data store and key management backend._" It is one of the APIs available at [APILayer](https://apilayer.com/). Their [documentation](https://apilayer.com/marketplace/vault-api#documentation-tab) and a [blog](https://blog.apilayer.com/why-should-you-integrate-vault-api-into-your-system/) explain it's intended use pretty well but what caught my eye is it allows storage of unstructured text data of any size for a pretty low monthly fee (free if you limit the API calls to 100 per day). This is particularly interesting to me as I now have a simple way to control licensing and remote activation of software I distribute--rather than using a more sophisticated (and far more expensive) service like [Keygen](https://keygen.sh/).

### Delphi DataModule

Since I use Delphi and there doesn't seem to be any other libraries out there for this service already, I wrote my own. I built it as a DataModule using Delphi 11 Alexandria so if you want to use an older version of Delphi, you'll need to fork this repository as I'm only using this in new projects at the moment.

## Mobile Manager App - Coming

In addition to the DataModule that can be included in your Delphi project, I'm also building a simple management program. It allows you to locally store your VaultAPI key and browse the folders and files you have stored. It's being built with FireMonkey and I plan to make it available on mobile devices. Since, as I stated above, one of the main uses is to remotely control licensing of distributed apps, my plan is that with the mobile app, I can create a new license for a client and activate it using just my phone.
