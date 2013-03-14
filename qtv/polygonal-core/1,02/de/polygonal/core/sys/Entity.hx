/*
 *                            _/                                                    _/
 *       _/_/_/      _/_/    _/  _/    _/    _/_/_/    _/_/    _/_/_/      _/_/_/  _/
 *      _/    _/  _/    _/  _/  _/    _/  _/    _/  _/    _/  _/    _/  _/    _/  _/
 *     _/    _/  _/    _/  _/  _/    _/  _/    _/  _/    _/  _/    _/  _/    _/  _/
 *    _/_/_/      _/_/    _/    _/_/_/    _/_/_/    _/_/    _/    _/    _/_/_/  _/
 *   _/                            _/        _/
 *  _/                        _/_/      _/_/
 *
 * POLYGONAL - A HAXE LIBRARY FOR GAME DEVELOPERS
 * Copyright (c) 2009 Michael Baczynski, http://www.polygonal.de
 *
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files (the
 * "Software"), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to
 * the following conditions:
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
 * LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
 * OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
 * WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */
package de.polygonal.core.sys;

import de.polygonal.core.event.IObservable;
import de.polygonal.core.event.IObserver;
import de.polygonal.core.event.Observable;
import de.polygonal.core.fmt.Sprintf;
import de.polygonal.core.math.Limits;
import de.polygonal.core.util.ClassUtil;
import de.polygonal.ds.Bits;
import de.polygonal.ds.Hashable;
import de.polygonal.ds.HashKey;
import de.polygonal.ds.IntHashSet;
import de.polygonal.ds.TreeNode;
import de.polygonal.core.util.Assert;

//descendant: ignore ghosts
//onAddChild, onRemoveChild

@:build(de.polygonal.core.sys.EntityType.gen())
@:autoBuild(de.polygonal.core.sys.EntityType.gen())
class Entity implements IObserver, implements IObservable, implements Hashable
{
	inline public static var UPDATE_ANCESTOR_ADD      = BIT_ADD_ANCESTOR;
	inline public static var UPDATE_ANCESTOR_REMOVE   = BIT_REMOVE_ANCESTOR;
	
	inline public static var UPDATE_DESCENDANT_ADD    = BIT_ADD_DESCENDANT;
	inline public static var UPDATE_DESCENDANT_REMOVE = BIT_REMOVE_DESCENDANT;
	
	inline public static var UPDATE_SIBLING_ADD       = BIT_ADD_SIBLING;
	inline public static var UPDATE_SIBLING_REMOVE    = BIT_REMOVE_SIBLING;
	
	inline public static var UPDATE_ANCESTOR          = BIT_ADD_ANCESTOR | BIT_REMOVE_ANCESTOR;
	inline public static var UPDATE_DESCENDANT        = BIT_ADD_DESCENDANT | BIT_REMOVE_DESCENDANT;
	inline public static var UPDATE_SIBLING           = BIT_ADD_SIBLING | BIT_REMOVE_SIBLING;
	inline public static var UPDATE_ALL               = UPDATE_ANCESTOR | UPDATE_DESCENDANT | UPDATE_SIBLING;
	
	inline static var BIT_TICK              = Bits.BIT_01;
	inline static var BIT_DRAW              = Bits.BIT_02;
	inline static var BIT_PROCESS_SUBTREE   = Bits.BIT_03;
	inline static var BIT_PENDING_ADD       = Bits.BIT_04;
	inline static var BIT_PENDING_REMOVE    = Bits.BIT_05;
	inline static var BIT_ADDED             = Bits.BIT_06;
	inline static var BIT_REMOVED           = Bits.BIT_07;
	inline static var BIT_PROCESS           = Bits.BIT_08;
	inline static var BIT_COMMIT_REMOVAL    = Bits.BIT_09;
	inline static var BIT_COMMIT_SUICIDE    = Bits.BIT_10;
	inline static var BIT_INITIATOR         = Bits.BIT_11;
	inline static var BIT_RECOMMIT          = Bits.BIT_12;
	inline static var BIT_ADD_ANCESTOR      = Bits.BIT_13;
	inline static var BIT_REMOVE_ANCESTOR   = Bits.BIT_14;
	inline static var BIT_ADD_DESCENDANT    = Bits.BIT_15;
	inline static var BIT_REMOVE_DESCENDANT = Bits.BIT_16;
	inline static var BIT_ADD_SIBLING       = Bits.BIT_17;
	inline static var BIT_REMOVE_SIBLING    = Bits.BIT_18;
	inline static var BIT_TICK_BEFORE_SLEEP = Bits.BIT_19;
	inline static var BIT_DRAW_BEFORE_SLEEP = Bits.BIT_20;
	
	inline static var BIT_PENDING = BIT_PENDING_ADD | BIT_PENDING_REMOVE;
	
	static var typeMap = new IntHashSet(512);
	
	#if verbose
	inline static var INDEX_ADD               = 0;
	inline static var INDEX_REMOVE            = 1;
	inline static var INDEX_ADD_ANCESTOR      = 2;
	inline static var INDEX_REMOVE_ANCESTOR   = 3;
	inline static var INDEX_ADD_DESCENDANT    = 4;
	inline static var INDEX_REMOVE_DESCENDANT = 5;
	inline static var INDEX_ADD_SIBLING       = 6;
	inline static var INDEX_REMOVE_SIBLING    = 7;
	inline static var INDEX_SUM               = 8;
	static var _stats = [0, 0, 0, 0, 0, 0, 0, 0, 0];
	public static function printTopologyStats():String
	{
		if (_stats[INDEX_ADD] == 0) return null;
		return Sprintf.format('+%-3d-%-3d|A:%-5d %-5d|D:%-5d %-5d|S:%-5d %-5d|%04d', _stats);
	}
	#end
	
	public static var format:Entity->String = null;
	
	/**
	 * The id of this entity.<br/>
	 * The default value is the unqualified class name of this object.
	 */
	public var id:String;
	
	/**
	 * The processing order of this entity.<br/>
	 * The smaller the value, the higher the priority.<br/>
	 * The default value is 0xFFFF.
	 */
	public var priority:Int;
	
	/**
	 * Custom data associated with this object.
	 */
	public var userData:Dynamic;
	
	/**
	 * If false, <em>onTick()</em> is not called on this entity.<br/>
	 * Default ist true.
	 */
	public var doTick(get_doTick, set_doTick):Bool;
	function get_doTick():Bool
	{
		return hasf(BIT_TICK);
	}
	function set_doTick(value:Bool):Bool
	{
		value ? setf(BIT_TICK) : clrf(BIT_TICK);
		return value;
	}
	
	/**
	 * If false, <em>onDraw()</em> is not called on this entity.<br/>
	 * Default ist false.
	 */
	public var doDraw(get_doDraw, set_doDraw):Bool;
	function get_doDraw():Bool
	{
		return hasf(BIT_DRAW);
	}
	function set_doDraw(value:Bool):Bool
	{
		value ? setf(BIT_DRAW) : clrf(BIT_DRAW);
		return value;
	}
	
	/**
	 * If false, all descendants of this node are neither updated nor rendered.<br/>
	 * Default is true.
	 */
	public var doChildren(get_doChildren, set_doChildren):Bool;
	function get_doChildren():Bool
	{
		return hasf(BIT_PROCESS_SUBTREE);
	}
	function set_doChildren(value:Bool):Bool
	{
		value ? setf(BIT_PROCESS_SUBTREE) : clrf(BIT_PROCESS_SUBTREE);
		return value;
	}
	
	/**
	 * The tree node storing this entity.
	 */
	public var treeNode(default, null):TreeNode<Entity>;
	
	/**
	 * A unique identifier for this object.<br/>
	 * A hash table transforms this key into an index of an array element by using a hash function.<br/>
	 * <warn>This value should never be changed by the user.</warn>
	 */
	public var key:Int;
	
	var _flags:Int;
	var _observable:Observable;
	var _c:Int;
	var _type:Int;
	
	public function new(id:String = null)
	{
		this.id = id == null ? ClassUtil.getUnqualifiedClassName(this) : id;
		key = HashKey.next();
		treeNode = new TreeNode<Entity>(this);
		priority = Limits.UINT16_MAX;
		_flags = BIT_TICK | BIT_PROCESS_SUBTREE | UPDATE_ALL;
		_observable = null;
		_c = 0;
		
		var c = Type.getClass(this);
		_type = getClassType(c);
		if (!typeMap.has(_type))
		{
			var a = _type;
			var m = typeMap;
			m.set(a);
			m.set((a << 16) | a);
			var s = Type.getSuperClass(c);
			while (s != null)
			{
				var b = getClassType(s);
				m.set((a << 16) | b);
				s = Type.getSuperClass(s);
			}
		}
		
		EntityManager.registerEntity(this);
	}
	
	/**
	 * Recursively destroys the subtree rooted at this entity (including this entity) from the bottom up.<br/>
	 * The method invokes <em>onFree()</em> on each entity, giving each entity the opportunity to perform some cleanup (e.g. free resources or unregister from listeners).<br/>
	 * Only effective if <em>commit()</em> is called afterwards.
	 */
	public function free():Void
	{
		if (hasf(BIT_COMMIT_SUICIDE))
		{
			#if verbose
			Root.warn(Sprintf.format('entity \'%s\' already freed', [Std.string(id)]));
			#end
			return;
		}
		
		//TODO why only with parents?
		if (treeNode.hasParent())
		{
			setf(BIT_COMMIT_SUICIDE);
			remove();
		}
	}
	
	/**
	 * An iterator over all children (non-recursive).<br/>
	 * Convenience method for <em>treeNode.childIterator()</em>.
	 */
	inline public function iterator():Iterator<Entity>
	{
		return treeNode.childIterator();
	}
	
	public function hideUpdate(flags:Int, deep = false, rise = false):Void
	{
		clrf(flags);
		
		if (deep)
		{
			var n = treeNode.children;
			while (n != null)
			{
				n.val.hideUpdate(flags);
				n = n.next;
			}
		}
		if (rise)
		{
			var n = treeNode.parent;
			while (n != null)
			{
				n.val.hideUpdate(flags);
				n = n.parent;
			}
		}
	}
	
	/**
	 * <ul>
	 * <li>Stops message propagation if called inside <em>onMsg()</em>.</li>
	 * <li>Stops calling <em>onTick()</em> on all descendants if called inside <em>onTick()</em>.</li>
	 * <li>Stops calling <em>onDraw()</em> on all descendants if called inside <em>onDraw()</em>.</li>
	 * </ul>
	 */
	inline public function stop():Void
	{
		_c++;
	}
	
	/**
	 * Returns the parent entity or null if this entity is not a child.
	 */
	inline public function getParent():Entity
	{
		return treeNode.hasParent() ? treeNode.parent.val : null;
	}
	
	/**
	 * Returns true if this entity is a child entity.
	 */
	inline public function hasParent():Bool
	{
		return treeNode.hasParent();
	}
	
	public function getChildAtIndex<T>(i:Int):T
	{
		#if debug
		D.assert(i >= 0 && i < treeNode.numChildren(), 'index out of range');
		#end
		
		var n = treeNode.children;
		for (j in 0...i) n = n.next;
		return cast n.val;
	}
	
	/**
	 * Sorts the children according to their <em>priority</em> value.
	 */
	public function sortChildren():Void
	{
		var n = treeNode.children;
		while (n != null)
		{
			if (n.val.priority < Limits.INT16_MAX)
			{
				treeNode.sort(sortChildrenCompare, true);
				break;
			}
			n = n.next;
		}
	}
	
	/**
	 * Carries out any pending changes (additions/removals).
	 */
	public function commit():Void
	{
		#if verbose
		for (i in 0...9) _stats[i] = 0;
		#end
		
		#if verbose
		if (treeNode != treeNode.getRoot())
			Root.debug('commit() called at child entity ' + id);
		#end
		
		//always start at root node
		if (!treeNode.isRoot())
		{
			treeNode.getRoot().val.commit();
			return;
		}
		
		//defer update if tree is being processed
		if (hasf(BIT_INITIATOR))
		{
			#if verbose
			Root.debug('postpone commit() at entity ' + id);
			#end
			setf(BIT_RECOMMIT);
			return;
		}
		
		//nothing changed - early out
		if (!isDirty())
		{
			clrf(BIT_INITIATOR | BIT_RECOMMIT);
			return;
		}
		
		//lock; this node carries out all changes
		setf(BIT_INITIATOR);
		
		//preorder traversal: for all nodes: replace PENDING bit with PROCESS bit
		prepareAdditions();
		registerHi();
		registerLo();
		register();
		
		prepareRemovals();
		unregisterHi();
		unregisterLo();
		unregister();
		removeNodes();
		
		//unlock
		clrf(BIT_INITIATOR);
		
		//recursive update?
		if (hasf(BIT_RECOMMIT))
		{
			#if verbose
			Root.warn('carry out recursive commit() at entity ' + id);
			#end
			clrf(BIT_RECOMMIT);
			commit();
		}
	}

	/**
	 * Updates all entities in the subtree rooted at this node (excluding this node) by calling <em>onTick()</em> on all descendants.
	 * @param timeDelta the time step passed to each descendant.
	 */
	public function tick(timeDelta:Float, parent:Entity = null):Void
	{
		propagateTick(timeDelta, parent == null ? this : parent);
	}
	
	/**
	 * Renders all entities in the subtree rooted at this node (excluding this node) by calling <em>onRender()</em> on all descendants.
	 * @param alpha a blending factor in the range <arg>&#091;0, 1&#093;</arg> between the previous and current state.
	 */
	public function draw(alpha:Float, parent:Entity = null):Void
	{
		propagateDraw(alpha, parent == null ? this : parent);
	}
	
	/**
	 * Adds a child entity to this entity.
	 * @param x an object inheriting from Entity or a reference to an Entity class.
	 */
	public function add(x:Dynamic, priority = Limits.UINT16_MAX):Entity
	{
		#if debug
		D.assert(x != null, 'x is null');
		#end
		
		var c:Entity =
		#if flash
		if (untyped x.hasOwnProperty('prototype'))
		#else
		if (Type.getClass(x) == null)
		#end
			cast Type.createInstance(x, []);
		else
			x;
		
		if (c.hasf(BIT_PENDING_ADD))
		{
			#if verbose
			Root.warn(Sprintf.format('entity \'%s\' already added to %s', [c.id, id]));
			#end
			return c;
		}
		
		if (c.hasf(BIT_PENDING_REMOVE))
		{
			//marked for removal, just update flags
			c.clrf(BIT_PENDING_REMOVE);
			c.setf(BIT_PENDING_ADD);
			if (c.priority != priority) c.priority = priority;
			return c;
		}
		
		#if debug
		D.assert(!treeNode.contains(c), 'given entity is a child of this entity');
		#end
		#if verbose
		if (treeNode.getRoot().val.hasf(BIT_INITIATOR))
			Root.warn(Sprintf.format('entity \'%s\' added during tree update', [c.id]));
		#end
		
		if (priority != Limits.UINT16_MAX) c.priority = priority;
		
		//modify tree
		treeNode.appendNode(c.treeNode);
		
		//mark as pending addition
		c.clrf(BIT_PENDING_REMOVE);
		c.setf(BIT_PENDING_ADD);
		
		return c;
	}
	
	/**
	 * Removes a <code>child</code> entity from this entity or this entity if <code>child</code> is omitted.
	 * @param deep if true, recursively removes all nodes in the subtree rooted at this node.
	 */
	public function remove(child:Entity = null, deep = false):Void
	{
		if (child == null)
		{
			//remove this entity
			if (getParent() == null)
			{
				#if verbose
				Root.warn('root node can\'t be removed.');
				#end
				return;
			}
			getParent().remove(this, deep);
			return;
		}
		
		if (child.hasf(BIT_PENDING_REMOVE | BIT_COMMIT_REMOVAL))
		{
			#if verbose
			Root.warn(Sprintf.format('entity \'%s\' already removed from \'%s\'', [Std.string(child.id), Std.string(id)]));
			#end
			return;
		}
		
		#if debug
		D.assert(child != this, 'given entity (%s) equals this entity.');
		D.assert(treeNode.contains(child), Sprintf.format('given entity (%s) is not a child of this entity (%s).', [Std.string(child.id), Std.string(id)]));
		#end
		#if verbose
		if (treeNode.getRoot().val.hasf(BIT_INITIATOR))
			Root.warn(Sprintf.format('entity \'%s\' removed during tree update', [child.id]));
		#end
		
		//TODO also sleep subtree?
		//put to sleep
		child.clrf(BIT_TICK | BIT_DRAW);
		
		//mark as pending removal
		child.clrf(BIT_PENDING_ADD);
		child.setf(BIT_PENDING_REMOVE);
		
		if (hasf(BIT_COMMIT_REMOVAL))
		{
			//this node was marked for removal, so child can be removed directly
			child.setf(BIT_COMMIT_REMOVAL);
			child.clrf(BIT_PENDING_REMOVE);
			child.clrf(BIT_TICK | BIT_DRAW);
			child.onRemove(this);
			#if verbose
			_stats[INDEX_REMOVE]++;
			_stats[INDEX_SUM]++;
			#end
		}
		
		if (deep)
		{
			var n = child.treeNode.children;
			while (n != null)
			{
				remove(n.val, deep);
				n = n.next;
			}
		}
	}
	
	/**
	 * Removes all child entities.
	 * @param deep if true, recursively removes all nodes in the subtree rooted at this node.
	 */
	public function removeChildren(deep = false):Entity
	{
		var n = treeNode.children;
		while (n != null)
		{
			remove(n.val);
			if (deep) n.val.removeChildren(deep);
			n = n.next;
		}
		return this;
	}
	
	/**
	 * Returns the first child whose class or subclass matches <code>x</code>
	 * or null if no entity was found.
	 */
	public function child<T:Entity>(x:Class<T>):T
	{
		var a = getClassType(x);
		var m = Entity.typeMap;
		var n = treeNode.children;
		while (n != null)
		{
			var e = n.val;
			if (m.has((e._type << 16) | a))
				return cast e;
			n = n.next;
		}
		return null;
	}
	
	/**
	 * Returns the first child whose <em>id</em> matches <code>x</code>
	 * or null if no entity was found.
	 */
	public function childById(x:String):Entity
	{
		var n = treeNode.children;
		while (n != null)
		{
			if (n.val.id == x)
				return n.val;
			n = n.next;
		}
		return null;
	}
	
	/**
	 * Returns the first descendant whose class or subclass matches <code>x</code>
	 * or null if no entity was found.<br/>
	 * In constrast to <em>c</em>, this method is recursive and searches the entire subtree.
	 */
	public function descendant<T:Entity>(x:Class<T>):T
	{
		var a = getClassType(x);
		var m = Entity.typeMap;
		var n = treeNode.children;
		while (n != null)
		{
			var e = n.val;
			if (m.has((e._type << 16) | a))
				return cast e;
			
			var t = e.descendant(x);
			if (t != null) return t;
			
			n = n.next;
		}
		return null;
	}
	
	/**
	 * Returns the first descendant whose <em>id</em> matches <code>x</code>
	 * or null if no entity was found.<br/>
	 * In constrast to <em>cid</em>, this method is recursive and searches the entire subtree.
	 */
	public function descendantById(x:String):Entity
	{
		var n = treeNode.children;
		while (n != null)
		{
			if (n.val.id == x) return n.val;
			var e = n.val.descendantById(x);
			if (e != null) return e;
			n = n.next;
		}
		return null;
	}
	
	/**
	 * Returns the first sibling whose class or subclass matches <code>x</code> or null if no entity was found.
	 */
	public function sibling<T:Entity>(x:Class<T>):T
	{
		var a = getClassType(x);
		var n = treeNode.getFirstSibling();
		var m = Entity.typeMap;
		while (n != null)
		{
			var e = n.val;
			if (m.has((e._type << 16) | a))
				return cast e;
			n = n.next;
		}
		return null;
	}
	
	/**
	 * Returns the first sibling whose <em>id</em> matches <code>x</code> or null if no entity was found.
	 */
	public function siblingById(x:String):Entity
	{
		var n = treeNode.getFirstSibling();
		while (n != null)
		{
			var e = n.val;
			if (e.id == x) return e;
			n = n.next;
		}
		return null;
	}
	
	/**
	 * Returns the first ancestor whose class or subclass matches <code>x</code> or null if no entity was found.
	 */
	public function ancestor<T:Entity>(x:Class<T>):T
	{
		var a = getClassType(x);
		var n = treeNode.parent;
		var m = Entity.typeMap;
		while (n != null)
		{
			var e = n.val;
			if (m.has((e._type << 16) | a))
				return cast e;
			n = n.parent;
		}
		return null;
	}
	
	/**
	 * Returns the first ancestor whose <em>id</em> matches <code>x</code> or null if no entity was found.
	 */
	public function ancestorById(x:String):Entity
	{
		var n = treeNode.parent;
		while (n != null)
		{
			var e = n.val;
			if (e.id == x) return e;
			n = n.parent;
		}
		return null;
	}
	
	/**
	 * Sends a message <code>x</code> to all ancestors of this node until it reaches the root node.<br/>
	 * If an ancestor calls <em>stop()</em>, message bubbling stops at this node.
	 * @param userData additional custom data.
	 */
	public function liftMsg(x:String, userData:Dynamic = null):Void
	{
		var n = treeNode.parent;
		while (n != null)
		{
			var e = n.val;
			if (e.isGhost()) break;
			
			var c = e._c;
			e.onMsg(x, this, userData);
			if (c < e._c)
			{
				e._c--;
				break;
			}
			
			n = n.parent;
		}
	}
	
	/**
	 * Sends a message <code>x</code> to all descendants of this node, until it reaches all leaf nodes.<br/>
	 * If a descendant calls <em>stop()</em>, the subtree of the current node is excluded from further message propagation.
	 * @param userData additional custom data.
	 * @param sender used internally.
	 */
	public function dropMsg(x:String, userData:Dynamic = null, sender:Entity = null):Void
	{
		if (sender == null) sender = this;
		
		var n = treeNode.children;
		while (n != null)
		{
			var e = n.val;
			if (e.isGhost())
			{
				n = n.next;
				continue;
			}
			
			var c = e._c;
			e.onMsg(x, sender, userData);
			if (c < e._c)
			{
				e._c--;
				n = n.next;
				continue;
			}
			e.dropMsg(x, userData, sender);
			
			n = n.next;
		}
	}
	
	/**
	 * Sends a message <code>x</code> to all siblings of this node.<br/>
	 * First, the message is sent to all siblings 'left' of this node (following <em>treeNode</em>.prev),
	 * then to siblings 'right' of this node (following <em>treeNode</em>.next).<br/>
	 * If a sibling calls <em>stop()</em>, propagation stops, excluding all siblings 'left' or 'right' of the current
	 * node.
	 * @param userData additional custom data.
	 */
	public function slipMsg(x:String, userData:Dynamic = null):Void
	{
		var n = treeNode.prev;
		while (n != null)
		{
			var e = n.val;
			if (e.isGhost())
			{
				n = n.prev;
				continue;
			}
			
			var c = e._c;
			e.onMsg(x, this, userData);
			if (c < e._c)
			{
				e._c--;
				break;
			}
			
			n = n.prev;
		}
		
		n = treeNode.next;
		while (n != null)
		{
			var e = n.val;
			if (e.isGhost())
			{
				n = n.next;
				continue;
			}
			
			var c = e._c;
			e.onMsg(x, this, userData);
			if (c < e._c)
			{
				e._c--;
				break;
			}
			
			n = n.next;
		}
	}
	
	/**
	 * Convenience method for Std.is(this, <code>x</code>);
	 */
	inline public function is<T>(x:Class<T>):Bool
	{
		#if flash
		return untyped __is__(this, x);
		#else
		return Std.is(this, x);
		#end
	}
	
	/**
	 * Handles multiple calls to <em>is()</em> in one shot by checking all classes in <code>x</code> against this class.
	 */
	public function isAny(x:Array<Class<Dynamic>>):Bool
	{
		for (i in x)
		{
			if (Std.is(this, i))
				return true;
		}
		return false;
	}
	
	public function sleep(deep = false):Void
	{
		clrf(BIT_TICK_BEFORE_SLEEP | BIT_DRAW_BEFORE_SLEEP);
		if (hasf(BIT_TICK)) setf(BIT_TICK_BEFORE_SLEEP);
		if (hasf(BIT_DRAW)) setf(BIT_DRAW_BEFORE_SLEEP);
		
		if (deep)
			clrf(BIT_TICK | BIT_DRAW | BIT_PROCESS_SUBTREE);
		else
			clrf(BIT_TICK | BIT_DRAW);
	}
	
	public function wakeup(deep = false):Void
	{
		if (hasf(BIT_TICK_BEFORE_SLEEP)) setf(BIT_TICK);
		if (hasf(BIT_DRAW_BEFORE_SLEEP)) setf(BIT_DRAW);
		
		if (deep) setf(BIT_PROCESS_SUBTREE);
	}
	
	public function toString():String
	{
		if (format != null) return format(this);
		
		if (treeNode == null)
			return Sprintf.format('[id=%s (freed)]', [Std.string(id)]);
		
		if (priority != Limits.UINT16_MAX)
			return Sprintf.format('[id=%s #c=%d, p=%02d%s]', [Std.string(id), treeNode.numChildren(), priority, hasf(BIT_PENDING) ? ' p' : '']);
		else
			return Sprintf.format('[id=%s #c=%d%s]', [Std.string(id), treeNode.numChildren(), hasf(BIT_PENDING) ? ' p' : '']);
	}
	
	public function getObservable():Observable
	{
		if (_observable == null)
			_observable = new Observable(0, this);
		return _observable;
	}
	
	public function attach(o:IObserver, mask = 0):Void
	{
		getObservable().attach(o, mask);
	}
	
	public function detach(o:IObserver, mask = 0):Void
	{
		if (_observable != null) getObservable().detach(o, mask);
	}
	
	public function notify(type:Int, userData:Dynamic = null):Void
	{
		getObservable().notify(type, userData);
	}
	
	public function update(type:Int, source:IObservable, userData:Dynamic):Void {}
	
	public function sendMsg(receiverId:String, msg:String, userData:Dynamic = null):Void
	{
		EntityManager.sendMsg(this, receiverId, msg, userData);
	}
	
	/**
	 * Hook; invoked after <code>sender</code> has sent a message <code>msg</code> to this entity, passing <code>userData</code>.
	 */
	public function onMsg(msg:String, sender:Entity, userData:Dynamic):Void {}
	
	/**
	 * Hook; invoked by <em>free()</em> on all children,
	 * giving each one the opportunity to perform some cleanup.
	 */
	function onFree():Void {}
	
	/**
	 * Hook; invoked after this entity was attached to its parent <code>x</code>.
	 */
	function onAdd(parent:Entity):Void {}

	/**
	 * Hook; invoked after an ancestor <code>x</code> was added to this entity.
	 */
	function onAddAncestor(x:Entity):Void {}
	
	/**
	 * Hook; invoked after a descendant <code>x</code> was added to this entity.
	 */
	function onAddDescendant(x:Entity):Void {}
	
	/**
	 * Hook; invoked after a sibling <code>x</code> was added to this entity.
	 */
	function onAddSibling(x:Entity):Void {}
	
	/**
	 * Hook; invoked after this entity was removed from its parent <code>x</code>.
	 */
	function onRemove(parent:Entity):Void {}
	
	/**
	 * Hook; invoked after this entity has lost the ancestor <code>x</code>.
	 */
	function onRemoveAncestor(x:Entity):Void {}
	
	/**
	 * Hook; invoked after this entity has lost the descendant <code>x</code>.
	 */
	function onRemoveDescendant(x:Entity):Void {}
	
	/**
	 * Hook; invoked after this entity has lost the sibling <code>x</code>.
	 */
	function onRemoveSibling(x:Entity):Void {}
	
	/**
	 * Hook; updates this entity.
	 */
	function onTick(timeDelta:Float, parent:Entity):Void {}
	
	/**
	 * Hook; renders this entity.
	 */
	function onDraw(alpha:Float, parent:Entity):Void {}
	
	function prepareAdditions():Void
	{
		//preorder: change BIT_PENDING_ADD to BIT_PROCESS
		if (hasf(BIT_PENDING_ADD))
		{
			clrf(BIT_PENDING_ADD);
			setf(BIT_PROCESS);
		}
		var n = treeNode.children;
		while (n != null)
		{
			n.val.prepareAdditions();
			n = n.next;
		}
	}
	
	function registerHi():Void
	{
		//bottom -> up construction
		var n = treeNode.children;
		while (n != null)
		{
			n.val.registerHi();
			n = n.next;
		}
		
		var p = treeNode.parent;
		if (p != null)
		{
			if (hasf(BIT_PROCESS))
				propagateOnAddAncestor(p.val);
			else 
			{
				if (getf(BIT_PENDING | BIT_ADD_ANCESTOR) == BIT_ADD_ANCESTOR)
					propagateOnAddAncestorBackTrack(p.val);
			}
		}
	}
	
	function propagateOnAddAncestor(x:Entity):Void
	{
		//only for non-pending nodes
		if (getf(BIT_PENDING | BIT_ADD_ANCESTOR) == BIT_ADD_ANCESTOR)
		{
			#if verbose
			_stats[INDEX_ADD_ANCESTOR]++;
			_stats[INDEX_SUM]++;
			#end
			onAddAncestor(x);
		}
		
		if (hasf(BIT_ADD_ANCESTOR))
		{
			//call onAddAncestor() on all descendants
			var n = treeNode.children;
			while (n != null)
			{
				var e = n.val;
				if (!e.hasf(BIT_PENDING))
					e.propagateOnAddAncestor(x);
				n = n.next;
			}
		}
	}
	
	function propagateOnAddAncestorBackTrack(x:Entity):Void
	{
		if (hasf(BIT_PROCESS))
		{
			propagateOnAddAncestor(x);
			return;
		}
		var n = treeNode.children;
		while (n != null)
		{
			var e = n.val;
			if (e.getf(BIT_PENDING) == 0)
				e.propagateOnAddAncestorBackTrack(x);
			n = n.next;
		}
	}
	
	function registerLo():Void
	{
		//postorder: bottom -> up construction
		var n = treeNode.children;
		while (n != null)
		{
			n.val.registerLo();
			n = n.next;
		}
		var p = treeNode.parent;
		if (p != null)
		{
			if (getf(BIT_PROCESS | BIT_ADD_DESCENDANT) == (BIT_PROCESS | BIT_ADD_DESCENDANT))
				propagateOnAddDescendant(p.val);
			else
			{
				if (getf(BIT_PENDING | BIT_ADD_DESCENDANT) == BIT_ADD_DESCENDANT)
					propagateOnAddDescendantBackTrack(p.val);
			}
		}
	}
	
	function propagateOnAddDescendant(x:Entity):Void
	{
		if (x.getf(BIT_PENDING | BIT_ADD_DESCENDANT) == BIT_ADD_DESCENDANT)
		{
			#if verbose
			_stats[INDEX_ADD_DESCENDANT]++;
			_stats[INDEX_SUM]++;
			#end
			x.onAddDescendant(this);
		}
		
		if (hasf(BIT_ADD_DESCENDANT))
		{
			var n = treeNode.children;
			while (n != null)
			{
				var e = n.val;
				if (e.getf(BIT_PENDING | BIT_ADD_DESCENDANT) == BIT_ADD_DESCENDANT)
					e.propagateOnAddDescendant(x);
				n = n.next;
			}
		}
	}
	
	function propagateOnAddDescendantBackTrack(x:Entity):Void
	{
		if (hasf(BIT_PROCESS))
		{
			propagateOnAddDescendant(x);
			return;
		}
		var n = treeNode.children;
		while (n != null)
		{
			var e = n.val;
			if (e.getf(BIT_PENDING | BIT_ADD_DESCENDANT) == BIT_ADD_DESCENDANT)
				e.propagateOnAddDescendantBackTrack(x);
			n = n.next;
		}
	}
	
	function register():Void
	{
		//postorder
		var n = treeNode.children;
		while (n != null)
		{
			n.val.register();
			n = n.next;
		}
		if (hasf(BIT_PROCESS))
		{
			var p = treeNode.parent.val;
			
			if (hasf(BIT_ADD_SIBLING))
				p.propagateOnAddSibling(this);
			
			onAdd(p);
			#if verbose
			_stats[INDEX_ADD]++;
			_stats[INDEX_SUM]++;
			#end
		}
		clrf(BIT_PROCESS);
	}
	
	function propagateOnAddSibling(child:Entity):Void
	{
		child.setf(BIT_ADDED);
		var n = treeNode.children;
		while (n != null)
		{
			var e = n.val;
			if (!e.hasf(BIT_ADDED))
			{
				e.onAddSibling(child);
				child.onAddSibling(e);
				#if verbose
				_stats[INDEX_ADD_SIBLING]++;
				_stats[INDEX_ADD_SIBLING]++;
				_stats[INDEX_SUM]++;
				#end
			}
			n = n.next;
		}
	}
	
	function prepareRemovals():Void
	{
		if (hasf(BIT_PENDING_REMOVE))
		{
			clrf(BIT_PENDING_REMOVE);
			setf(BIT_PROCESS);
		}
		var n = treeNode.children;
		while (n != null)
		{
			n.val.prepareRemovals();
			n = n.next;
		}
	}
	
	function unregister():Void
	{
		var n = treeNode.children;
		while (n != null)
		{
			n.val.unregister();
			n = n.next;
		}
		
		if (treeNode.parent == null) return;
		
		if (hasf(BIT_PROCESS))
		{
			setf(BIT_COMMIT_REMOVAL);
			var p = treeNode.parent.val;
			onRemove(p);
			
			if (hasf(BIT_REMOVE_SIBLING))
				p.propagateOnRemoveSibling(this);
		}
	}
	
	function propagateOnRemoveSibling(child:Entity):Void
	{
		child.setf(BIT_REMOVED);
		var n = treeNode.children;
		while (n != null)
		{
			var e = n.val;
			if (!e.hasf(BIT_REMOVED))
			{
				e.onRemoveSibling(child);
				child.onRemoveSibling(e);
				#if verbose
				_stats[INDEX_REMOVE_SIBLING]++;
				_stats[INDEX_REMOVE_SIBLING]++;
				_stats[INDEX_SUM]++;
				#end
			}
			n = n.next;
		}
	}
	
	function unregisterHi():Void
	{
		var n = treeNode.children;
		while (n != null)
		{
			n.val.unregisterHi();
			n = n.next;
		}
		var p = treeNode.parent;
		if (hasf(BIT_PROCESS))
			propagateOnRemoveAncestor(p.val);
		else
		{
			if (p == null) return;
			if (hasf(BIT_PENDING)) return;
			if (treeNode.children == null) return;
			propagateOnRemoveAncestorBackTrack(p.val);
		}
	}
	
	function propagateOnRemoveAncestor(x:Entity):Void
	{
		if (getf(BIT_PENDING | BIT_REMOVE_ANCESTOR) == BIT_REMOVE_ANCESTOR)
		{
			onRemoveAncestor(x);
			#if verbose
			_stats[INDEX_REMOVE_ANCESTOR]++;
			_stats[INDEX_SUM]++;
			#end
		}
		
		//propagate to children?
		if (hasf(BIT_REMOVE_ANCESTOR))
		{
			var n = treeNode.children;
			while (n != null)
			{
				var e = n.val;
				if (!e.hasf(BIT_PENDING))
					e.propagateOnRemoveAncestor(x);
				n = n.next;
			}
		}
	}
	
	function propagateOnRemoveAncestorBackTrack(x:Entity):Void
	{
		if (hasf(BIT_PROCESS))
		{
			propagateOnRemoveAncestor(x);
			return;
		}
		var n = treeNode.children;
		while (n != null)
		{
			var e = n.val;
			if (e.getf(BIT_PENDING) == 0)
				e.propagateOnRemoveAncestorBackTrack(x);
			n = n.next;
		}
	}
	
	function unregisterLo():Void
	{
		var n = treeNode.children;
		while (n != null)
		{
			n.val.unregisterLo();
			n = n.next;
		}
		var p = treeNode.parent;
		if (getf(BIT_PROCESS | BIT_REMOVE_DESCENDANT) == (BIT_PROCESS | BIT_REMOVE_DESCENDANT))
			propagateOnRemoveDescendant(p.val);
		else
		{
			if (p == null) return;
			if (getf(BIT_PENDING | BIT_REMOVE_DESCENDANT) == BIT_PENDING) return;
			if (treeNode.children == null) return;
			propagateOnRemoveDescendantBackTrack(p.val);
		}
	}
	
	function propagateOnRemoveDescendant(x:Entity):Void
	{
		if (x.getf(BIT_PENDING | BIT_REMOVE_DESCENDANT) == BIT_REMOVE_DESCENDANT)
		{
			x.onRemoveDescendant(this);
			#if verbose
			_stats[INDEX_REMOVE_DESCENDANT]++;
			_stats[INDEX_SUM]++;
			#end
		}
		
		if (hasf(BIT_REMOVE_DESCENDANT))
		{
			var n = treeNode.children;
			while (n != null)
			{
				var e = n.val;
				if (e.getf(BIT_PENDING | BIT_REMOVE_DESCENDANT) == BIT_REMOVE_DESCENDANT)
					e.propagateOnRemoveDescendant(x);
				n = n.next;
			}
		}
	}
	
	function propagateOnRemoveDescendantBackTrack(x:Entity):Void
	{
		if (getf(BIT_PROCESS | BIT_REMOVE_DESCENDANT) == (BIT_PROCESS | BIT_REMOVE_DESCENDANT))
		{
			propagateOnRemoveDescendant(x);
			return;
		}
		var n = treeNode.children;
		while (n != null)
		{
			var e = n.val;
			if (e.getf(BIT_PENDING | BIT_REMOVE_DESCENDANT) == BIT_REMOVE_DESCENDANT)
				e.propagateOnRemoveDescendantBackTrack(x);
			n = n.next;
		}
	}
	
	function removeNodes():Void
	{
		var n = treeNode.children;
		while (n != null)
		{
			var hook = n.next;
			n.val.removeNodes();
			n = hook;
		}
		
		sortChildren();
		
		if (hasf(BIT_COMMIT_REMOVAL))
		{
			treeNode.unlink();
			//recursively destroy subtree rooted at this node?
			if (hasf(BIT_COMMIT_SUICIDE)) propagateFree();
		}
		
		clrf(BIT_PROCESS | BIT_COMMIT_REMOVAL | BIT_ADDED | BIT_REMOVED);
	}
	
	function propagateTick(timeDelta:Float, parent:Entity):Void
	{
		#if debug
		D.assert(treeNode != null, 'treeNode != null');
		#end
		
		var n = treeNode.children;
		while (n != null)
		{
			var e = n.val;
			if (e.isGhost())
			{
				n = n.next;
				continue;
			}
			
			if (e.hasf(BIT_TICK))
			{
				var c = e._c;
				e.onTick(timeDelta, parent);
				
				if (c < e._c)
					e._c--;
				else
				if (e.hasf(BIT_PROCESS_SUBTREE))
					e.propagateTick(timeDelta, e);
			}
			else
			if (e.hasf(BIT_PROCESS_SUBTREE))
				e.propagateTick(timeDelta, e);
			
			n = n.next;
		}
	}
	
	function propagateDraw(alpha:Float, parent:Entity):Void
	{
		#if debug
		D.assert(treeNode != null, 'treeNode != null');
		#end
		
		var n = treeNode.children;
		while (n != null)
		{
			var e = n.val;
			if (e.isGhost())
			{
				n = n.next;
				continue;
			}
			
			if (e.hasf(BIT_DRAW))
			{
				var c = e._c;
				e.onDraw(alpha, parent);
				if (c < e._c)
					e._c--;
				else
				if (e.hasf(BIT_PROCESS_SUBTREE))
					e.propagateDraw(alpha, e);
			}
			else
			if (e.hasf(BIT_PROCESS_SUBTREE))
				e.propagateDraw(alpha, e);
			
			n = n.next;
		}
	}
	
	function sortChildrenCompare(a:Entity, b:Entity):Int
	{
		return a.priority - b.priority;
	}
	
	function propagateFree():Void
	{
		var tmp = treeNode;
		treeNode.postorder
		(
			function(n, u)
			{
				var e = n.val;
				if (e._observable != null)
				{
					e._observable.free();
					e._observable = null;
				}
				e.treeNode = null;
				e.onFree();
				EntityManager.unregisterEntity(e);
				return true;
			});
		tmp.free();
	}
	
	function isDirty():Bool
	{
		if (hasf(BIT_PENDING)) return true;
		var n = treeNode.children;
		while (n != null)
		{
			if (n.val.isDirty()) return true;
			n = n.next;
		}
		return false;
	}
	
	inline function getClassType<T>(C:Class<T>):Int
	{
		#if flash
		return untyped C.___type;
		#else
		return Reflect.field(C, '___type');
		#end
	}
	
	inline function isGhost():Bool
	{
		return hasf(BIT_PENDING | BIT_COMMIT_SUICIDE);
	}
	
	inline function getf(mask:Int):Int
	{
		return _flags & mask;
	}
	
	inline function hasf(mask:Int):Bool
	{
		return _flags & mask > 0;
	}
	
	inline function setf(mask:Int):Void
	{
		_flags |= mask;
	}
	
	inline function clrf(mask:Int):Void
	{
		_flags &= ~mask;
	}
}