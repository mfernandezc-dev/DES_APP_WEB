package com.fernandez.tecsup.repository;
import com.fernandez.tecsup.model.Producto;
import org.springframework.data.jpa.repository.JpaRepository;
public interface ProductoRepository extends JpaRepository<Producto, Long> {}