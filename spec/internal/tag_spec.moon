import do_setup from require 'spec.test_setup'
import Tag from require 'alv.tag'
import Registry from require 'alv.registry'

setup do_setup

describe 'Tag', ->
  describe 'should be constructable', ->
    it 'by parsing', ->
      tag = Tag.parse '2'
      assert tag
      assert.is.equal 2, tag.value
      assert.is.equal '[2]', tag\stringify!
      assert.is.equal '2', tostring tag

    it 'as blank Tags', ->
      tag = Tag.blank!
      assert tag
      assert.is.nil tag.value
      assert.is.equal '', tag\stringify!
      assert.is.equal '?', tostring tag

  describe 'should be clonable', ->
    do_asserts = (tag, expect) ->
      assert tag
      assert.is.nil tag.value
      assert.is.equal expect, tostring tag
      assert.has.error tag\stringify

    it 'from parsed tags', ->
      parent = Tag.parse '1'
      original = Tag.parse '2'
      tag = original\clone parent
      do_asserts tag, '1.2'

    it 'but not from blank tags', ->
      parent = Tag.parse '1'
      original = Tag.blank!
      tag = original\clone parent
      do_asserts tag, '1.?'

    it 'with blank parent', ->
      parent = Tag.blank!
      original = Tag.parse '2'
      tag = original\clone parent
      do_asserts tag, '?.2'

    it 'completely blank', ->
      parent = Tag.blank!
      original = Tag.blank!
      tag = original\clone parent
      do_asserts tag, '?.?'

  describe 'should be set-able', ->
    it 'only if blank',  ->
      tag = Tag.parse '42'
      assert.has.error -> tag\set 43

      clone = tag\clone Tag.parse '3'
      assert.has.error -> clone\set 42

      clone = tag\clone Tag.blank!
      assert.has.error -> clone\set 42

    it 'and stores the value', ->
      blank = Tag.blank!
      blank\set 12

      assert.is.equal blank.value, 12

    it 'sets the original if cloned', ->
      original = Tag.blank!
      parent = Tag.parse '7'

      o_set = spy.on original, 'set'
      p_set = spy.on parent, 'set'

      clone = original\clone parent
      clone\set 11

      assert.spy(o_set).was_called_with (match.is_ref original), 11
      assert.spy(p_set).was_not_called!

      assert.is.equal original.value, 11
 
    it 'requires the parent to be registered if cloned', ->
      original = Tag.blank!
      parent = Tag.blank!

      clone = original\clone parent
      assert.has.error -> clone\set 11
