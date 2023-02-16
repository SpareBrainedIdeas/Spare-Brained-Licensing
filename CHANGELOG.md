
# Change Log

## [2.0.202307.109] - 2023-02-16
 
Massive refactoring.  **Note: Breaking changes**

### Added
- New Platform built in, [Lemon Squeezy](https://www.lemonsqueezy.com/)

### Changed
- **Breaking Change:** All events refactored into a new Event Wrapper codeunit
- **Breaking Change:** Checking if a license is active moved to new codeunit for the purpose. This is in prep for more complex checking, such as metered usage scenarios
- **Breaking Change:** Interface for alternative platforms now has more procedure signatures to be more platform agnostic in logic flows.
- Restructure of Files/Folders to add developer clarity
- Refactor of entire Extension to comply better with SOLID principles
- Additional documentation added to codeunits/procedures

### Notice

Due to the sheer volume of breaking changes, the commit history on this repo is NOT completely detailing all changes.  This repo is a PTE *clone* of the AppSource app (renamed and renumbered, so they can co-exist) which is on our Public Azure DevOps site.

## [1.0.202224.23] - 2022-06-06
 
Lots of fixes, tweaks, and v20 changeover.  New Submodule option for licensing.
 
### Added
- New "Submodule" support.  Extensions can now have Submodules for licensing separate functionality with different keys
 
### Changed
- Version 20 target
- Per [#3](https://github.com/SpareBrainedIdeas/Spare-Brained-Licensing/issues/3), locking many captions that should not translate
- Environment awareness so licensing resets Grace info on Sandbox copies
 
### Fixed
- [#5](https://github.com/SpareBrainedIdeas/Spare-Brained-Licensing/issues/5), fixing IsoStore format
- [#6](https://github.com/SpareBrainedIdeas/Spare-Brained-Licensing/issues/6), fixing wizard Back behavior
- [#8](https://github.com/SpareBrainedIdeas/Spare-Brained-Licensing/issues/8), very improved Grace handling
 
## [1.0.0.0] - 2021-11-24
 
### Added
   
- Created.  Public version is in parity with AppSource v.1.0.0.0, but has different (PTE) object IDs and names, so both may coexist if needed.