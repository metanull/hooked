# MWNFExhibitions

A thin MWNF-specific module for managing Exhibition deployment

## Install

```powershell
Import-Module $HOOKED_DIR\src\MWNFExhibition\MWNFExhibitions.psm1
```

## Dependency

- MetaNull.PSStringToolkit
- MetaNull.PSGitOps
- MetaNull.PSCredentialCache
- MetaNull.PSDeployQueue
- MetaNull.PSWebAppBuilder

## Highlights

- Declares `RequiredModules`: MetaNull.PSStringToolkit, MetaNull.PSGitOps, MetaNull.PSCredentialCache, MetaNull.PSDeployQueue
- Hosts exhibition-specific functions: `Install-Exhibition`, `Uninstall-Exhibition`, `Get-Exhibition`, `Publish-Exhibition`, `Unpublish-Exhibition`
- Hosts `Import-ExhibitionServerConfiguration`, `Set-ExhibitionServerDatabaseCredential`
- Hosts validation: `Test-ExhibitionName`, `Test-LanguageId`

This module is NOT published to PSGallery — it's MWNF-specific.

## License

MIT
