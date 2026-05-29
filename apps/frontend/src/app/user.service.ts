// ============================================================
//  USER SERVICE (Angular) — gọi API backend
// ============================================================
//  Type User, CreateUserDto, ... import từ @leng/shared
//  → cùng định nghĩa với backend, không drift.
// ============================================================
import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import type { User, CreateUserDto, UpdateUserDto } from '@leng/shared';

@Injectable({ providedIn: 'root' })
export class UserService {
  private http = inject(HttpClient);
  private base = '/api/users'; // qua proxy → backend localhost:8080

  list() {
    return this.http.get<User[]>(this.base);
  }

  getById(id: string) {
    return this.http.get<User>(`${this.base}/${id}`);
  }

  create(dto: CreateUserDto) {
    return this.http.post<User>(this.base, dto);
  }

  update(id: string, dto: UpdateUserDto) {
    return this.http.patch<User>(`${this.base}/${id}`, dto);
  }

  remove(id: string) {
    return this.http.delete<void>(`${this.base}/${id}`);
  }
}
