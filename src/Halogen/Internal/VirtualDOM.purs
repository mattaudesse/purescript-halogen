module Halogen.Internal.VirtualDOM
  ( VTree()
  , Patch()
  , Props()
  , STProps()
  , emptyProps
  , prop
  , handlerProp
  , newProps
  , runProps
  , createElement
  , diff
  , patch
  , vtext
  , vnode
  , hash
  , widget
  ) where

import DOM

import Data.Maybe
import Data.Nullable
import Data.Function

import Control.Monad.Eff
import Control.Monad.ST

data VTree

data Patch

data Props

data STProps h

foreign import emptyProps 
  "var emptyProps = {}" :: Props

foreign import prop
  "function prop(key, value, props) {\
  \  return function() {\
  \    props[key] = value;\
  \  };\
  \}" :: forall h value eff. Fn3 String value (STProps h) (Eff (st :: ST h | eff) Unit)

foreign import handlerProp
  "function handlerProp(key, f, props) {\
  \  return function() {\
  \    var Hook = function () {};\
  \    Hook.prototype.callback = function(e) {\
  \      f(e)();\
  \    };\
  \    Hook.prototype.hook = function(node) {\
  \      node.addEventListener(key, this.callback);\
  \    };\
  \    Hook.prototype.unhook = function(node) {\
  \      node.removeEventListener(key, this.callback);\
  \    };\
  \    props['data-halogen-hook-' + key] = new Hook(f);\
  \  };\
  \}" :: forall h eff eff1 event. Fn3 String (event -> Eff eff1 Unit) (STProps h) (Eff (st :: ST h | eff) Unit)

foreign import newProps 
  "function newProps() {\
  \  return {};\
  \}" :: forall h eff. Eff (st :: ST h | eff) (STProps h)
  
foreign import runProps
  "function runProps(props) {\
  \  return props();\
  \}" :: (forall h eff. Eff (st :: ST h | eff) (STProps h)) -> Props

foreign import createElement
  "function createElement(vtree) {\
  \  return require('virtual-dom/create-element')(vtree);\
  \}" :: VTree -> Node

foreign import diff
  "function diff(vtree1) {\
  \  return function createElement(vtree2) {\
  \    return require('virtual-dom/diff')(vtree1, vtree2);\
  \  };\
  \}" :: VTree -> VTree -> Patch
  
foreign import patch
  "function patch(p) {\
  \  return function(node) {\
  \    return function() {\
  \      return require('virtual-dom/patch')(node, p);\
  \    };\
  \  };\
  \}" :: forall eff. Patch -> Node -> Eff (dom :: DOM | eff) Node
  
foreign import vtext 
  "function vtext(s) {\
  \  var VText = require('virtual-dom/vnode/vtext');\
  \  return new VText(s);\
  \}" :: String -> VTree

foreign import vnode 
  "function vnode(name) {\
  \  return function(props) {\
  \    return function(children) {\
  \      var VirtualNode = require('virtual-dom/vnode/vnode');\
  \      return new VirtualNode(name, props, children);\
  \    };\
  \  };\
  \}" :: String -> Props -> [VTree] -> VTree

foreign import hash
  "function hash(f, hash) {\
  \  var HashThunk = function(hash) {\
  \    this.hash = hash;\
  \  };\
  \  HashThunk.prototype.type = 'Thunk';\
  \  HashThunk.prototype.render = function(prev) {\
  \    if (prev && prev.hash === this.hash) {\
  \      return prev.vnode;\
  \    } else {\
  \      return f();\
  \    }\
  \  };\
  \  return new HashThunk(hash);\
  \}" :: Fn2 (Fn0 VTree) String VTree
  
foreign import widgetImpl
  "function widgetImpl(init, update, destroy) {\
  \  var Widget = function () {};\
  \  Widget.prototype.type = 'Widget';\
  \  Widget.prototype.init = function(){\
  \    return init();\
  \  };\
  \  Widget.prototype.update = function(prev, node) {\
  \    return update(node)();\
  \  };\
  \  Widget.prototype.destroy = function(node) {\
  \    destroy(node)();\
  \  };\
  \  return new Widget();\
  \}" :: forall eff. Fn3 (Eff eff Node) (Node -> Eff eff (Nullable Node)) (Node -> Eff eff Unit) VTree

widget :: forall eff. Eff eff Node -> (Node -> Eff eff (Maybe Node)) -> (Node -> Eff eff Unit) -> VTree
widget init update destroy = runFn3 widgetImpl init (\n -> toNullable <$> update n) destroy