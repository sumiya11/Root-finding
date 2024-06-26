using Symbolics 

function sub(sub_counter, subs, place_to_sub)
    sub_var = Symbolics.variables("c"*string(sub_counter))[1]
    subs[sub_var] = deepcopy(place_to_sub)
    place_to_sub = sub_var.val
    sub_counter += 1
    return sub_counter, place_to_sub
end


function filter_poly(og_expr, var)
    expr = deepcopy(og_expr)
    expr = Symbolics.unwrap(expr)
    if isequal(Symbolics.get_variables(expr)[1], expr)
        return (Dict(), Symbolics.wrap(expr))
    end

    args = unsorted_arguments(expr)
    subs = Dict()
    sub_counter = 1
    for (i, arg) in enumerate(args)
        # handle constants
        vars = Symbolics.get_variables(arg)
        type_arg = typeof(arg)
        if isequal(vars, [])
            if type_arg == Int64 || type_arg == Rational{Int64}
                continue
            end
            sub_counter, args[i] = sub(sub_counter, subs, args[i])
            continue
        end

        # handle "x" as an argument
        if length(vars) == 1
            if isequal(arg, var)
                continue
            elseif isequal(vars[1], arg)
                sub_counter, args[i] = sub(sub_counter, subs, args[i])
                continue
            end
        end
        
        oper = Symbolics.operation(arg)
        if oper === (^)
            monomial = unsorted_arguments(arg)
            if any(arg -> isequal(arg, var), monomial) 
                continue
            end
            sub_counter, args[i] = sub(sub_counter, subs, args[i])
            continue
        end

        monomial = unsorted_arguments(args[i])
        for (j, x) in enumerate(monomial)
            type_x = typeof(x)
            vars = Symbolics.get_variables(x)
            if (!isequal(vars, []) && isequal(vars[1], var))  || isequal(type_x, Int64) || isequal(type_x, Rational{Int64})
                continue
            end
            sub_counter, monomial[j] = sub(sub_counter, subs, monomial[j])
        end
    end
    return (subs, Symbolics.wrap(expr))
end


function lead_term(expr, var)
    subs, expr = filter_poly(expr, var)
    coeffs, constant = polynomial_coeffs(expr, [var])
    degree = Symbolics.degree(expr, var)
    lead_term = coeffs[var^degree]*var^degree
    for (var, sub) in subs
        lead_term = Symbolics.substitute(lead_term, Dict([var => sub]), fold=false)
    end

    return lead_term
end

function lead_coeff(expr, var)
    degree = Symbolics.degree(expr, var)
    lead_coeff = lead_term(expr, var) / (var^degree)
    return lead_coeff
end