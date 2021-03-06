// Adapted from https://github.com/leanprover/lean4/blob/IFL19/tests/bench/rbmap.lean

type color { 
  Red 
  Black 
}

type tree {
  con Leaf()
  con Node(color: color, lchild: tree, key: int, value: bool, rchild: tree)
}

fun fold(t: tree, b: a, f: (int, bool, a) -> a): a {
  match (t) {
    Leaf                -> b
    Node(_, l, k, v, r) -> r.fold( f(k, v, l.fold(b, f)), f)
  }
}

fun balance1(kv: int, vv: bool, t: tree, s: tree): tree {
  match(s) {
    Leaf -> Leaf
    Node(_, Node(Red, l, kx, vx, r1), ky, vy, r2)
      -> Node(Red, Node(Black, l, kx, vx, r1), ky, vy, Node(Black, r2, kv, vv, t))
    Node(_, l1, ky, vy, Node(Red, l2, kx, vx, r))
      -> Node(Red, Node(Black, l1, ky, vy, l2), kx, vx, Node(Black, r, kv, vv, t))
    Node(_, l, ky, vy, r)
      -> Node(Black, Node(Red, l, ky, vy, r), kv, vv, t)
  }
}

fun balance2(t: tree, kv: int, vv: bool, s: tree): tree {
  match(s) {
    Leaf -> Leaf
    Node(_, Node(Red, l, kx1, vx1, r1), ky, vy, r2)
      -> Node(Red, Node(Black, t, kv, vv, l), kx1, vx1, Node(Black, r1, ky, vy, r2))
    Node(_, l1, ky, vy, Node(Red, l2, kx2, vx2, r2))
      -> Node(Red, Node(Black, t, kv, vv, l1), ky, vy, Node(Black, l2, kx2, vx2, r2))
    Node(_, l, ky, vy, r)
      -> Node(Black, t, kv, vv, Node(Red, l, ky, vy, r))
  }
}

fun is-red(t : tree) : bool {
  match(t) {
    Node(Red) -> True
    _         -> False
  }
}

fun ins(t: tree, kx: int, vx: bool): tree {
  match(t) {
    Leaf -> Node(Red, Leaf, kx, vx, Leaf)
    Node(Red, a, ky, vy, b)
      | kx < ky   -> Node(Red, ins(a, kx, vx), ky, vy, b)
      | kx == ky  -> Node(Red, a, kx, vx, b)
      | _         -> Node(Red, a, ky, vy, ins(b, kx, vx))
    Node(Black, a, ky, vy, b)
      | kx < ky   -> if (is-red(a)) then balance1(ky, vy, b, ins(a, kx, vx))
                                    else Node(Black, ins(a, kx, vx), ky, vy, b)
      | kx == ky  -> Node(Black, a, kx, vx, b)
      | is-red(b) -> balance2(a, ky, vy, ins(b, kx, vx))
      | _         -> Node(Black, a, ky, vy, ins(b, kx, vx))
  }
}

fun set-black(t: tree) : tree {
  match(t) {
    Node(_, l, k, v, r) -> Node(Black, l, k, v, r)
    _ -> t
  }
}

fun insert(t: tree, k: int, v: bool): tree {
  if (is-red(t))
    then set-black(ins(t, k, v))
    else ins(t, k, v)
}

fun make-tree-aux(n: int, m: tree): div tree {
  if (n <= 0) then m else {
    val n1 = n - 1
    make-tree-aux(n1, insert(m, n1, n1 % 10 == 0))
  }
}

fun make-tree(n: int): div tree {
  make-tree-aux(n, Leaf)
}

fun main() {
  val m = make-tree(4200000); // todo: read first command line arg for size
  val v = m.fold(0) fun(k,v,r){ if (v) then r + 1 else r }
  v.println
}
