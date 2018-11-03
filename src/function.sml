(*
    Copyright 2018 Fernando Borretti <fernando@borretti.me>

    This file is part of Boreal.

    Boreal is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    Boreal is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Boreal.  If not, see <http://www.gnu.org/licenses/>.
*)

structure Function :> FUNCTION = struct
    (* Type aliases *)

    type name = Symbol.symbol
    type ty = Type.ty
    type docstring = string option

    (* Concrete functions *)

    datatype func = Function of name * param list * ty * docstring
         and param = Param of name * ty

    fun functionName (Function (name, _, _, _)) =
        name

    (* Foreign functions *)

    datatype ffunc = ForeignFunction of name * param list * foreign_arity * ty * docstring
         and foreign_arity = FixedArity
                           | VariableArity

    (* Generic functions *)

    datatype gfunc = GenericFunction of name * Type.typarams * param list * ty * docstring

    fun gFunctionName (GenericFunction (name, _, _, _, _)) =
        name

    fun isRTP (GenericFunction (_, _, params, rt, _)) =
        let val paramVars = Set.unionList (map (fn (Param (name, ty)) => Type.tyVars ty) params)
            and rtVars = Type.tyVars rt
        in
            (* The set difference of the rtVars and paramVars is the set of
               all type variables that are in the rtVars but not in the
               paramVars. If this set is non-empty, return true. *)
            (Set.size (Set.difference rtVars paramVars)) > 0
        end

    (* Typeclasses *)

    type param_name = Symbol.symbol

    datatype typeclass = Typeclass of name * param_name * docstring * method_decl list
         and method_decl = MethodDecl of name * param list * ty * docstring

    fun typeclassName (Typeclass (name, _, _, _)) =
        name

    datatype instance = Instance of name * instance_arg * docstring * method_def list
         and instance_arg = InstanceArg of name * Type.typarams
         and method_def = MethodDef of name * param list * ty * docstring

    fun instanceName (Instance (name, _, _, _)) =
        name

    (* Function environments *)

    datatype fenv = FunctionEnv of (name, func) Map.map
                                   * (name, ffunc) Map.map
                                   * (name, gfunc) Map.map
                                   * typeclass list
                                   * instance list

    val defaultFenv =
        let fun funcName (Function (name, _, _, _)) =
                name
        in
            let val notFn = Function (Symbol.au "not",
                                      [Param (Symbol.au "v", Type.Bool)],
                                      Type.Bool,
                                      NONE)
            in
                let val builtins = [notFn]
                in
                    FunctionEnv (Map.fromList (map (fn f => (funcName f, f)) builtins),
                                 Map.empty,
                                 Map.empty,
                                 [],
                                 [])
                end
            end
        end

    fun findTypeclassByName (FunctionEnv (_, _, _, ts, _)) name =
        let fun isValidTC (Typeclass (name', _, _, _)) =
                name = name'
        in
            List.find isValidTC ts
        end

    fun findTypeclassByMethod (FunctionEnv (_, _, _, ts, _)) name =
        let fun isValidTC (Typeclass (_, _, _, methods)) =
                Option.isSome (List.find isValidMethod methods)
            and isValidMethod (MethodDecl (name', _, _, _)) =
                name = name'
        in
            List.find isValidTC ts
        end

    fun addFunction (FunctionEnv (fm, ffm, gm, ts, is)) f =
        let val name = functionName f
        in
            (* If there's a function with this name, fail *)
            case Map.get fm name of
                SOME _ => NONE
              | NONE =>
                (* If there's a gfunc with this name also fail *)
                case Map.get gm name of
                    SOME _ => NONE
                  | NONE => SOME (FunctionEnv (Map.iadd fm (name, f), gm, ts, is))
        end

    fun addGenericFunction (FunctionEnv (fm, gm, ts, is)) gf =
        let val name = gFunctionName gf
        in
            (* If there's a function with this name, fail *)
            case Map.get fm name of
                SOME _ => NONE
              | NONE =>
                (* If there's a gfunc with this name also fail *)
                case Map.get gm name of
                    SOME _ => NONE
                  | NONE => SOME (FunctionEnv (fm, Map.iadd gm (name, gf), ts, is))
        end

    fun addTypeclass fenv tc =
        (case findTypeclassByName fenv (typeclassName tc) of
             SOME _ => NONE
           | _ => let val (FunctionEnv (fm, gm, ts, is)) = fenv
                  in
                      SOME (FunctionEnv (fm, gm, tc :: ts, is))
                  end)

    fun addInstance fenv ins =
        (case findTypeclassByName fenv (instanceName ins) of
             SOME _ => let val (FunctionEnv (fm, gm, ts, is)) = fenv
                       in
                           SOME (FunctionEnv (fm, gm, ts, ins :: is))
                       end
           | _ => NONE)

    datatype callable = CallableFunc of func
                      | CallableGFunc of gfunc
                      | CallableMethod

    fun envGet menv name =
        let val (FunctionEnv (funs, gfuncs, classes, instances)) = menv
        in
            case Map.get funs name of
                SOME f => SOME (CallableFunc f)
              | NONE => case Map.get gfuncs name of
                            SOME gf => SOME (CallableGFunc gf)
                          | NONE => NONE
        end

    fun matchParams params types =
        let val paramTypes = map (fn (Param (_, t)) => t) params
        in
            let val binds = TypeMatch.matchTypeLists paramTypes types
            in
                case binds of
                    TypeMatch.Bindings m => m
                  | TypeMatch.Failure f => raise Fail ("Argument matching failure: " ^ f)
            end
        end

    fun matchFunc params rt argTypes rt' =
        let val binds = matchParams params argTypes
        in
            let val binds' = TypeMatch.matchType rt rt'
            in
                let val binds'' = TypeMatch.mergeBindings (TypeMatch.Bindings binds) binds'
                in
                    case binds'' of
                        (TypeMatch.Bindings m) => m
                      | TypeMatch.Failure f => raise Fail ("Argument matching failure: " ^ f)
                end
            end
        end

    fun typeArgs params bindings =
        let fun mapParam (Type.TypeParam name) =
                case Map.get bindings name of
                    SOME ty => ty
                  | NONE => raise Fail ("typeArgs: unbound type variable: " ^ (Symbol.toString name))
        in
            map mapParam (OrderedSet.toList params)
        end
end
