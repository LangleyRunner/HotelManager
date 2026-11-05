
package com.hotelmanager.backend.model;

import jakarta.persistence.*;
import jakarta.validation.constraints.*;
import java.math.BigDecimal;

@Entity
@Table(name = "habitaciones")
public class Habitacion {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true)
    @NotNull @Min(1) private Integer numero;

    @Column(nullable = false)
    @NotBlank @Size(max=100) private String tipo;

    @Column(nullable = false, precision = 10, scale = 2)
    @NotNull @DecimalMin("0.00") @Digits(integer=8, fraction=2) private BigDecimal precio;

    @Column(nullable = false)
    @NotNull private Boolean disponible = true;

    // Nullable for existing records: the administrator supplies the real values when editing.
    @Column
    private Integer capacidad;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "piso_id", foreignKey = @ForeignKey(name = "fk_habitacion_piso"))
    private Piso piso;

    @Enumerated(EnumType.STRING)
    @Column(name = "estado_operativo", length = 30)
    private EstadoOperativo estadoOperativo;

    public Integer getCapacidad() { return capacidad; }
    public void setCapacidad(Integer capacidad) { this.capacidad = capacidad; }
    public Piso getPiso() { return piso; }
    public void setPiso(Piso piso) { this.piso = piso; }
    public EstadoOperativo getEstadoOperativo() { return estadoOperativo; }
    public void setEstadoOperativo(EstadoOperativo estadoOperativo) { this.estadoOperativo = estadoOperativo; }

    public Habitacion() {
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public Integer getNumero() {
        return numero;
    }

    public void setNumero(Integer numero) {
        this.numero = numero;
    }

    public String getTipo() {
        return tipo;
    }

    public void setTipo(String tipo) {
        this.tipo = tipo;
    }

    public BigDecimal getPrecio() {
        return precio;
    }

    public void setPrecio(BigDecimal precio) {
        this.precio = precio;
    }

    public Boolean getDisponible() {
        return disponible;
    }

    public void setDisponible(Boolean disponible) {
        this.disponible = disponible;
    }
}
