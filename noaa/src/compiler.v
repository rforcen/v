module noaa

import strconv
import math

const stack_size = 8

pub enum Token {
	null   = 0
	number = 1
	string = 2

	ident        = 3
	identstation = 4

	plus   = 5
	minus  = 6
	mult   = 7
	div    = 8
	oparen = 9
	cparen = 10
	comma  = 13

	eq = 14
	ne = 15
	lt = 16
	le = 17
	gt = 18
	ge = 19

	and = 20
	or  = 21
	not = 22

	any    = 23
	all    = 24
	value  = 25
	values = 26
	in     = 27

	// function names
	fabs = 101

	pushc       = 112
	pushfld     = 113
	pushs       = 114
	pushfldstat = 115

	neg = 116
}

pub type Float = f64

// helpers
fn is_alpha(ch char) bool {
	return (ch >= `a` && ch <= `z`) || (ch >= `A` && ch <= `Z`)
}

fn is_digit(ch char) bool {
	return ch >= `0` && ch <= `9`
}

fn is_alnum(ch char) bool {
	return is_alpha(ch) || is_digit(ch)
}

struct Compiler {
mut:
	expr string // expression to evaluate
	ixs  int    // expr index	

	sym    Token // actual sym
	ch     char  // actual ch
	nval   Float // actual numerical value
	fld_no int   // field number in daily obs.

	id  string // actual id,
	str string // string literal

	fconsts []Float   // constants table
	strs    []Fstring // Fstring table

	err bool

	err_message string
	seed        int

	uses_station bool
	uses_values  bool

	code []int

	stack Stack
}

const res_words = {
	'and':    Token.and
	'or':     Token.or
	'not':    Token.not
	'any':    Token.any
	'all':    Token.all
	'value':  Token.value
	'values': Token.values
	'in':     Token.in
	'abs':    Token.fabs
}

const daily_header = {
	'id':      0
	'country': 1
	'year':    2
	'month':   3
	'element': 4
}

const station_fields = {
	'latitude':  0
	'longitude': 1
	'elevation': 2
	'state':     3
}

const token_map = {
	rune(0): Token.null
	`+`:     Token.plus
	`-`:     Token.minus
	`*`:     Token.mult
	`/`:     Token.div
	`(`:     Token.oparen
	`)`:     Token.cparen
	`,`:     Token.comma
	`&`:     Token.and
	`|`:     Token.or
	`=`:     Token.eq
	`!`:     Token.not
	`<`:     Token.lt
	`>`:     Token.gt
}

const token_map2 = {
	`!`: Token.ne
	`<`: Token.le
	`>`: Token.ge
}

// run time
enum DataType { // Daily stack type any|all
	t_valany
	t_valall
}

struct Stack { // stack
mut:
	stack [stack_size]VarType
	sp    int
}

@[inline]
fn (mut st Stack) push(x &VarType) {
	st.stack[st.sp] = *x
	st.sp++
}

@[inline]
fn (mut st Stack) pushf(x Float) {
	st.stack[st.sp].set_f(&x)
	st.sp++
}

@[inline]
fn (mut st Stack) pushs(str &Fstring) {
	st.stack[st.sp].set_fs(str)
	st.sp++
}

@[inline]
fn (mut st Stack) push_any(mut rec Daily) {
	rec.lf = u8(DataType.t_valany)
	st.stack[st.sp].set_daily(&rec)
	st.sp++
}

@[inline]
fn (mut st Stack) push_all(mut rec Daily) {
	rec.lf = u8(DataType.t_valall)
	st.stack[st.sp].set_daily(&rec)
	st.sp++
}

/*
	Logical operation support
*/

// compare fn for Float & string
// logical operators =, !=, <, >, >=
@[inline]
fn cmp_eq(f1 &VarType, f2 &VarType) bool {
	return f1.eq(f2)
}

@[inline]
fn cmp_ne(f1 &VarType, f2 &VarType) bool {
	return f1.ne(f2)
}

@[inline]
fn cmp_gt(f1 &VarType, f2 &VarType) bool {
	return f1.gt(f2)
}

@[inline]
fn cmp_ge(f1 &VarType, f2 &VarType) bool {
	return f1.ge(f2)
}

@[inline]
fn cmp_lt(f1 &VarType, f2 &VarType) bool {
	return f1.lt(f2)
}

@[inline]
fn cmp_le(f1 &VarType, f2 &VarType) bool {
	return f1.le(f2)
}

type LogicalOperation = fn (&VarType, &VarType) bool

fn (mut stack [stack_size]VarType) logical_oper(sp int, cmp fn (&VarType, &VarType) bool) {
	match stack[sp - 1].tp {
		.dt_float, .dt_fstring, .dt_bool {
			stack[sp - 1].set_bool(cmp(&stack[sp - 1], &stack[sp]))
		}
		.dt_daily {
			match unsafe { DataType(stack[sp - 1].get_daily().lf) } {
				// .lf field is used as Daily value type (all|any)
				.t_valany {
					mut found := false
					mut vt := VarType{}
					for d in 0 .. 31 {
						ok, v := stack[sp - 1].get_daily().valid_value(d)
						vt.set_f(Float(v))
						if ok && cmp(&vt, &stack[sp]) {
							stack[sp - 1].set_bool(true)
							found = true
							break
						}
					}
					if !found {
						stack[sp - 1].set_bool(false)
					}
				}
				.t_valall {
					mut found := false
					mut vt := VarType{}
					for d in 0 .. 31 {
						ok, v := stack[sp - 1].get_daily().valid_value(d)
						vt.set_f(Float(v))
						if ok && !cmp(&vt, &stack[sp]) {
							stack[sp - 1].set_bool(false)
							found = true
							break
						}
					}
					if !found {
						stack[sp - 1].set_bool(true)
					}
				}
			}
		}
	}
}

@[inline]
fn (mut stack Stack) eq() {
	stack.sp--
	stack.stack.logical_oper(stack.sp, cmp_eq)
}

@[inline]
fn (mut stack Stack) ne() {
	stack.sp--
	stack.stack.logical_oper(stack.sp, cmp_ne)
}

@[inline]
fn (mut stack Stack) gt() {
	stack.sp--
	stack.stack.logical_oper(stack.sp, cmp_gt)
}

@[inline]
fn (mut stack Stack) ge() {
	stack.sp--
	stack.stack.logical_oper(stack.sp, cmp_ge)
}

@[inline]
fn (mut stack Stack) lt() {
	stack.sp--
	stack.stack.logical_oper(stack.sp, cmp_lt)
}

@[inline]
fn (mut stack Stack) le() {
	stack.sp--
	stack.stack.logical_oper(stack.sp, cmp_le)
}

/////

pub fn (mut c Compiler) evaluate(mut db Noaa_db) bool { // called for each Daily rec
	if c.code.len == 0 {
		return true
	}
	c.stack.sp = 0

	mut pc := 0
	for ; pc < c.code.len; pc++ {
		// unsafe { println(Token(c.code[pc])) }

		match unsafe { Token(c.code[pc]) } {
			.any {
				c.stack.push_any(mut db.daily)
			}
			.all {
				c.stack.push_all(mut db.daily)
			}
			.pushc {
				pc++
				c.stack.pushf(c.fconsts[c.code[pc]])
			}
			.pushs {
				pc++
				c.stack.pushs(c.strs[c.code[pc]])
			}
			.pushfld {
				pc++
				match unsafe { c.code[pc] } {
					0 { c.stack.pushs(db.daily.get_station()) }
					1 { c.stack.pushs(db.daily.get_country()) }
					2 { c.stack.pushf(Float(db.daily.get_year())) }
					3 { c.stack.pushf(Float(db.daily.get_month())) }
					4 { c.stack.pushs(db.daily.get_element()) }
					else { panic('${c.code[pc]} : unknown daily field code') } // error
				}
			}
			.pushfldstat { // push station field

				pc++
				match c.code[pc] {
					0 { c.stack.pushf(db.station.latitude) }
					1 { c.stack.pushf(db.station.longitude) }
					2 { c.stack.pushf(db.station.elevation) }
					3 { c.stack.pushs(fstr(db.station.state)) }
					else { panic('${c.code[pc]} : unknown station field code') } // error
				}
			}
			// logical cmp's
			.eq {
				c.stack.eq()
			}
			.ne {
				c.stack.ne()
			}
			.gt {
				c.stack.gt()
			}
			.ge {
				c.stack.ge()
			}
			.lt {
				c.stack.lt()
			}
			.le {
				c.stack.le()
			}
			.and {
				sp := c.stack.sp - 1
				c.stack.stack[sp - 1].set_bool((c.stack.stack[sp - 1].get_bool())
					&& (c.stack.stack[sp].get_bool()))
				c.stack.sp--
			}
			.or {
				sp := c.stack.sp - 1
				c.stack.stack[sp - 1].set_bool((c.stack.stack[sp - 1].get_bool())
					|| (c.stack.stack[sp].get_bool()))
				c.stack.sp--
			}
			.not {
				sp := c.stack.sp - 1
				c.stack.stack[sp].set_bool(!(c.stack.stack[sp].get_bool()))
			}
			.fabs {
				sp := c.stack.sp - 1
				c.stack.stack[sp].set_f(math.abs(c.stack.stack[sp].get_f()))
			}
			.plus {
				sp := c.stack.sp - 1
				c.stack.stack[sp - 1].set_f(c.stack.stack[sp - 1].get_f() +
					c.stack.stack[sp].get_f())
				c.stack.sp--
			}
			.minus {
				sp := c.stack.sp - 1
				c.stack.stack[sp - 1].set_f(c.stack.stack[sp - 1].get_f() - c.stack.stack[sp].get_f())
				c.stack.sp--
			}
			.mult {
				sp := c.stack.sp - 1
				c.stack.stack[sp - 1].set_f(c.stack.stack[sp - 1].get_f() * c.stack.stack[sp].get_f())
				c.stack.sp--
			}
			.div {
				sp := c.stack.sp - 1
				c.stack.stack[sp - 1].set_f(c.stack.stack[sp - 1].get_f() / c.stack.stack[sp].get_f())
				c.stack.sp--
			}
			.neg {
				sp := c.stack.sp - 1
				c.stack.stack[sp].set_f(-(c.stack.stack[sp].get_f()))
			}
			.in { // fld-3, r>=-2, f<=-1
				sp := c.stack.sp

				c.stack.stack[sp - 3].set_bool(
					c.stack.stack[sp - 3].get_f() >= c.stack.stack[sp - 2].get_f()
					&& c.stack.stack[sp - 3].get_f() <= c.stack.stack[sp - 1].get_f())

				c.stack.sp -= 2
			}
			else {
				c.error('pcode ${c.code[pc]} not supported')
				break
			}
		}
	}

	if c.stack.sp != 1 {
		panic('stack size error${c.stack.sp} is not 1')
	}
	return c.stack.stack[c.stack.sp - 1].get_bool()
}

pub fn compile(expr string) Compiler {
	mut c := Compiler{
		expr: expr
	}

	c.getch() // get first char
	c.getsym() // get symbol

	c.ce0()

	return c
}

fn (mut c Compiler) ce0() {
	if !c.err {
		c.ce00()
		for {
			sym_ := c.sym
			if sym_ in [Token.plus, Token.minus] {
				c.getsym()
				c.ce00()
				c.gen(sym_)
			} else {
				break
			}
		}
	}
}

fn (mut c Compiler) ce00() {
	if !c.err {
		c.ce1()
		for {
			sym_ := c.sym
			if sym_ in [Token.and, Token.or] {
				c.getsym()
				c.ce1()
				c.gen(sym_)
			} else {
				break
			}
		}
	}
}

fn (mut c Compiler) ce1() {
	if !c.err {
		c.ce3()
		for {
			sym_ := c.sym
			if sym_ in [Token.mult, Token.div] {
				c.getsym()
				c.ce3()
				c.gen(sym_)
			} else {
				break
			}
		}
	}
}

fn (mut c Compiler) ce3() {
	if !c.err {
		c.ce5()
		for {
			sym_ := c.sym
			match sym_ {
				.eq, .ne, .gt, .ge, .lt, .le {
					c.getsym()
					c.ce5()
					c.gen(sym_)
				}
				.in {
					c.getsym() // oparen
					c.getsym()
					c.ce0()
					c.getsym() // comma
					c.ce0()
					c.getsym() // cparen
					c.gen(Token.in)
				}
				else {}
			}
			if c.sym !in [Token.eq, Token.ne, Token.gt, Token.ge, Token.lt, Token.le, Token.in] {
				break
			}
		}
	}
}

fn (mut c Compiler) ce5() {
	if !c.err {
		match c.sym {
			.oparen {
				c.getsym()
				c.ce0()
				c.getsym()
			}
			.number {
				c.genf(Token.pushc, c.nval)
				c.getsym()
			}
			.string {
				c.gens(Token.pushs, c.str)
				c.getsym()
			}
			.ident {
				c.geni(Token.pushfld, c.fld_no)
				c.getsym()
			}
			.identstation {
				c.uses_station = true
				c.geni(Token.pushfldstat, c.fld_no)
				c.getsym()
			}
			.all {
				if c.getsym() == Token.values {
					c.getsym()
					c.gen(Token.all)
					c.uses_values = true
				} else {
					c.error('malformed "all values"')
				}
			}
			.any {
				if c.getsym() == Token.value {
					c.getsym()
					c.gen(Token.any)
					c.uses_values = true
				} else {
					c.error('malformed "any value"')
				}
			}
			.plus { // skip
				c.getsym()
				c.ce5()
			}
			.minus {
				c.getsym()
				c.ce5()
				c.gen(Token.neg)
			}
			.not {
				c.getsym()
				c.ce5()
				c.gen(Token.not)
			}
			.fabs {
				sym_ := c.sym
				c.getsym()
				c.ce5()
				c.gen(sym_)
			}
			.null {}
			else {
				c.error('unknown symbol:${c.sym}')
			}
		}
	}
}

fn (mut c Compiler) gen(sym Token) {
	c.code << int(sym)
}

fn (mut c Compiler) genf(sym Token, f Float) {
	c.code << int(sym)
	c.code << c.fconsts.len
	c.fconsts << f
}

fn (mut c Compiler) gens(sym Token, s string) {
	c.code << int(sym)
	c.code << c.strs.len
	c.strs << fstr(s)
}

fn (mut c Compiler) geni(sym Token, i int) {
	c.code << int(sym)
	c.code << i
}

fn (mut c Compiler) ungetch() {
	c.ixs--
	if c.ixs < 0 {
		c.ixs = 0
	}
}

fn (mut c Compiler) getch() char {
	c.ch = 0
	if c.ixs < c.expr.len {
		c.ch = c.expr[c.ixs]
		c.ixs++
	}
	return c.ch
}

fn (mut c Compiler) getsym() Token {
	c.sym = Token.null
	c.id = ''
	c.str = ''
	c.nval = 0

	for c.ch != 0 && c.ch <= ` ` {
		c.getch()
	} // skip blanks
	// println('getsym1: ${rune(c.ch).str()}, $c.ixs, $c.sym')

	if c.ch != 0 {
		if c.ch == `'` { // literal
			c.str = ''
			for c.getch() != `'` && c.ch != 0 {
				c.str += rune(c.ch).str()
			}
			c.sym = Token.string
			c.getch()
			// println('getsym2: $c.sym, $c.str')
		} else {
			if is_alpha(c.ch) {
				c.id = ''
				for is_alnum(c.ch) || c.ch == `_` {
					c.id += rune(c.ch).str()
					c.getch()
				}

				c.id.to_lower()
				if c.id in res_words {
					c.sym = res_words[c.id]
				}
				// reserved?
				else {
					if c.id in daily_header { // find in daily header
						c.fld_no = daily_header[c.id]
						c.sym = Token.ident
					} else {
						if c.id in station_fields {
							c.sym = Token.identstation
							c.fld_no = station_fields[c.id]
						} else {
							c.sym = Token.null
							eprintln('unknown symbol: ${c.id}')
						}
					}
				}
			} else {
				if is_digit(c.ch) {
					for is_digit(c.ch) || c.ch in [`.`, `e`, `E`] {
						c.id += rune(c.ch).str()
						c.getch()
					}
					c.sym = Token.number
					c.nval = strconv.atof64(c.id) or { // check number
						eprintln('malformed number: ${c.id}')
						0
					}
				} else {
					if c.ch in token_map {
						c.sym = token_map[c.ch]

						ch_ant := c.ch // 2 char symbol?
						if c.getch() == `=` { // != >= <=
							if ch_ant in token_map2 {
								c.sym = token_map2[ch_ant]
							} else {
								eprintln('char not recognized: ${rune(c.ch).str()}')
							}
						} else {
							if c.ch != 0 {
								c.ungetch()
							}
						}
						c.getch()
					} else {
						eprintln('char not recognized: ${rune(c.ch).str()}')
					}
				}
			}
		}
	}
	// println('getsym3: sym: $c.sym id:"$c.id" str:"$c.str" fld_no:$c.fld_no ixs:$c.ixs nval:$c.nval ch:${u8(c.ch)} ${rune(c.ch).str()}')
	return c.sym
}

fn (mut c Compiler) error(s string) {
	c.err_message = s
	c.err = true
}

pub fn (c Compiler) ok() bool {
	return !c.err
}

pub fn (c Compiler) get_err_msg() string {
	return c.err_message
}
