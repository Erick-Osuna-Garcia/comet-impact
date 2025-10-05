// crater_shader.gdshader
shader_type spatial;

// Estas variables las controlaremos desde GDScript
uniform vec3 impact_point;
uniform float crater_radius = 50.0;
uniform float crater_depth = -15.0;
// Esta variable la controlará el AnimationPlayer (de 0.0 a 1.0)
uniform float animation_progress = 0.0;

void vertex() {
    // Calcula la distancia de este vértice al punto de impacto
    float distance_to_impact = distance(VERTEX, impact_point);

    // Si el vértice está dentro del radio del cráter...
    if (distance_to_impact < crater_radius) {
        // Calcula qué tan profundo debe hundirse este vértice
        // Usamos una curva suave para que el cráter no tenga bordes duros
        float displacement_factor = (cos(distance_to_impact / crater_radius * PI) + 1.0) / 2.0;

        // Hundimos el vértice a lo largo de su normal (hacia el centro)
        // y lo multiplicamos por el progreso de la animación
        VERTEX += NORMAL * crater_depth * displacement_factor * animation_progress;
    }
}