extern crate pin_project;

// This works in 2018 edition, but in 2015 edition it gives an error: `pin` is ambiguous (derive helper attribute vs any other name)
// #[allow(unused_imports)]
// use pin_project as pin;

use pin_project::{pin_project, pinned_drop, UnsafeUnpin};
use std::pin::Pin;

include!("../../include/basic.rs");
